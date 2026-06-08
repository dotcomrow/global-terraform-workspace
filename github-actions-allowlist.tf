resource "terraform_data" "cleanup_github_actions_ruleset" {
  count = var.enable_github_actions_allowlist ? 0 : 1

  triggers_replace = [
    var.cloudflare_account_id,
    var.cloudflare_zone_id,
    var.cloudflare_token,
    var.github_actions_cloudflare_list_name,
    var.github_actions_bypass_host,
    var.github_actions_bypass_path_prefix,
    "skip_rate_limit_for_github_actions_apps_api",
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/sh", "-c"]

    command = <<-EOT
      set -eu

      python3 - "$CLOUDFLARE_ACCOUNT_ID" "$CLOUDFLARE_ZONE_ID" "$GITHUB_ACTIONS_LIST_NAME" "$GITHUB_ACTIONS_RULE_REF" <<'PY'
import json
import os
import sys
import urllib.error
import urllib.request

account_id = sys.argv[1]
zone_id = sys.argv[2]
list_name = sys.argv[3]
rule_ref = sys.argv[4]

token = os.environ.get("CLOUDFLARE_API_TOKEN", "").strip()
if not token:
    raise SystemExit("CLOUDFLARE_API_TOKEN is required.")

base_url = "https://api.cloudflare.com/client/v4"
headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json",
}


def api_request(method, url, payload=None):
    data = json.dumps(payload).encode("utf-8") if payload is not None else None
    request = urllib.request.Request(url, data=data, method=method, headers=headers)
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            body = response.read().decode("utf-8")
            parsed = json.loads(body) if body else {}
            return response.getcode(), parsed
    except urllib.error.HTTPError as error:
        body = error.read().decode("utf-8")
        parsed = {}
        if body:
            try:
                parsed = json.loads(body)
            except json.JSONDecodeError:
                parsed = {"raw": body}
        return error.code, parsed


def list_all(url):
    page = 1
    while True:
        sep = "&" if "?" in url else "?"
        status, payload = api_request("GET", f"{url}{sep}page={page}&per_page=100")

        if status == 404:
            return

        if not (200 <= status < 300) or not payload.get("success", False):
            print(f"Could not list {url}.")
            print(json.dumps(payload))
            raise SystemExit(1)

        for item in payload.get("result") or []:
            yield item

        info = payload.get("result_info") or {}
        current = int(info.get("page", 1))
        total = int(info.get("total_pages", current))
        if current >= total:
            return
        page += 1


def require_success(status, payload, context):
    success = bool(payload.get("success", False))
    if 200 <= status < 300 and success:
        return

    print(f"Cloudflare API request failed for {context}: HTTP {status}")
    if payload:
        print(json.dumps(payload))
    raise SystemExit(1)


def lookup_list_id():
    target_name = list_name.strip().lower()
    for item in list_all(f"{base_url}/accounts/{account_id}/rules/lists"):
        name = str(item.get("name") or "").strip().lower()
        if name == target_name:
            return str(item.get("id") or "").strip()
    return ""


def references_target_list(rule, target_list_id):
    expression = str(rule.get("expression") or "")
    if f"$${list_name}" in expression:
        return True
    if target_list_id and target_list_id in expression:
        return True

    serialized = json.dumps(rule)
    if f"$${list_name}" in serialized:
        return True
    if target_list_id and target_list_id in serialized:
        return True
    if str(rule.get("ref") or "") == rule_ref:
        return True
    return False


def delete_rule(scope_prefix, scope_id, ruleset_id, rule_id, context):
    if not ruleset_id or not rule_id:
        return

    delete_rule_url = f"{base_url}/{scope_prefix}/{scope_id}/rulesets/{ruleset_id}/rules/{rule_id}"
    status, result_payload = api_request("DELETE", delete_rule_url)

    if status in (404, 409):
        return
    if status == 405:
        print(f"Rule delete not supported for {context} ruleset {ruleset_id}; this rule may be immutable.")
        return
    if not (200 <= status < 300):
        require_success(status, result_payload, f"delete {context} rule {rule_id}")

    print(f"Removed {context} rule {rule_id} from ruleset {ruleset_id}.")


def remove_matching_rules(scope_prefix, scope_id, list_id):
    removed = 0
    for ruleset in list_all(f"{base_url}/{scope_prefix}/{scope_id}/rulesets"):
        ruleset_id = str(ruleset.get("id") or "").strip()
        for rule in ruleset.get("rules") or []:
            rule_id = str(rule.get("id") or "").strip()
            if not rule_id:
                continue
            if not references_target_list(rule, list_id):
                continue
            removed += 1
            context = "zone" if scope_prefix == "zones" else "account"
            delete_rule(scope_prefix, scope_id, ruleset_id, rule_id, context)
    return removed


def cleanup_entrypoint_rule(list_id):
    entrypoint_url = f"{base_url}/zones/{zone_id}/rulesets/phases/http_request_firewall_custom/entrypoint"
    status, payload = api_request("GET", entrypoint_url)

    if status == 404:
        print("No zone-level custom firewall entrypoint ruleset found; nothing to remove.")
        return

    if not (200 <= status < 300) or not payload.get("success", False):
        print("Could not read entrypoint ruleset.")
        print(json.dumps(payload))
        raise SystemExit(1)

    result = payload.get("result") or {}
    ruleset_id = str((result.get("id") or "")).strip()
    rules = result.get("rules") or []
    removed = 0

    for rule in rules:
        if str(rule.get("ref") or "").strip() == rule_ref or references_target_list(rule, list_id):
            rule_id = str(rule.get("id") or "").strip()
            if not rule_id:
                continue
            delete_rule("zones", zone_id, ruleset_id, rule_id, "zone entrypoint")
            removed += 1

    if removed == 0:
        print("No matching GitHub Actions bypass rule found in zone entrypoint.")

    # Attempt to delete the now-empty entrypoint ruleset.
    status, result_payload = api_request("GET", entrypoint_url)
    if 200 <= status < 300 and result_payload.get("success", False):
        ruleset = result_payload.get("result") or {}
        remaining_rules = ruleset.get("rules") or []
        if len(remaining_rules) == 0 and ruleset_id:
            delete_ruleset_url = f"{base_url}/zones/{zone_id}/rulesets/{ruleset_id}"
            status, delete_payload = api_request("DELETE", delete_ruleset_url)
            if status == 404:
                return
            if 200 <= status < 300:
                print(f"Deleted empty custom firewall entrypoint ruleset {ruleset_id}.")
                return

            print("Could not delete ruleset; leaving ruleset in place.")
            print(json.dumps(delete_payload))


def cleanup_list(list_id):
    if not list_id:
        print(f"List '{list_name}' not found; nothing to remove.")
        return

    delete_list_url = f"{base_url}/accounts/{account_id}/rules/lists/{list_id}"
    status, delete_payload = api_request("DELETE", delete_list_url)
    if status == 404:
        print(f"List '{list_name}' was already removed.")
        return
    if not (200 <= status < 300):
        print(f"Failed to delete list '{list_name}'.")
        print(json.dumps(delete_payload))
        raise SystemExit(1)
    print(f"Deleted list '{list_name}' ({list_id}).")


list_id = lookup_list_id()

zone_rules_removed = remove_matching_rules("zones", zone_id, list_id)
if zone_rules_removed:
    print(f"Removed {zone_rules_removed} zone ruleset rule(s) referencing '{list_name}'.")

# Keep entrypoint clean too, because the list was added by the old allowlist setup.
cleanup_entrypoint_rule(list_id)

account_rules_removed = remove_matching_rules("accounts", account_id, list_id)
if account_rules_removed:
    print(f"Removed {account_rules_removed} account ruleset rule(s) referencing '{list_name}'.")

# If the list still has references, this delete fails and surfaces remaining dependencies.
cleanup_list(list_id)
PY
    EOT

    environment = {
      CLOUDFLARE_API_TOKEN   = var.cloudflare_token
      CLOUDFLARE_ACCOUNT_ID  = var.cloudflare_account_id
      CLOUDFLARE_ZONE_ID     = var.cloudflare_zone_id
      GITHUB_ACTIONS_LIST_NAME = var.github_actions_cloudflare_list_name
      GITHUB_ACTIONS_RULE_REF = "skip_rate_limit_for_github_actions_apps_api"
    }
  }
}
