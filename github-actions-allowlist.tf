/*
data "http" "github_meta" {
  count = var.enable_github_actions_allowlist ? 1 : 0

  url = var.github_meta_api_url

  request_headers = {
    Accept               = "application/vnd.github+json"
    X-GitHub-Api-Version = var.github_meta_api_version
  }
}


locals {
  github_actions_list_name = var.github_actions_cloudflare_list_name

  github_actions_runner_cidrs = var.enable_github_actions_allowlist ? sort(distinct([
    for cidr in try(jsondecode(data.http.github_meta[0].response_body).actions, []) :
    trimspace(cidr)
    if trimspace(cidr) != ""
  ])) : []

  github_actions_list_reference = length(local.github_actions_runner_cidrs) > 0 ? format("$%s", local.github_actions_list_name) : ""

  github_actions_runner_items_hash = sha256(join(",", local.github_actions_runner_cidrs))

  github_actions_bypass_hosts = distinct([
    for host in [var.github_actions_bypass_host, "auth-origin.suncoast.systems"] :
    lower(trimspace(host))
    if trimspace(host) != ""
  ])

  github_actions_bypass_hosts_expression = join(
    " ",
    [for host in local.github_actions_bypass_hosts : format("%q", host)],
  )

  github_actions_rate_limit_bypass_expression = format(
    "(http.host in {%s} and starts_with(http.request.uri.path, %q) and ip.src in %s)",
    local.github_actions_bypass_hosts_expression,
    var.github_actions_bypass_path_prefix,
    local.github_actions_list_reference,
  )
}

resource "cloudflare_list" "github_actions_runners" {
  count = var.enable_github_actions_allowlist ? 1 : 0

  account_id  = var.cloudflare_account_id
  kind        = "ip"
  name        = local.github_actions_list_name
  description = "GitHub Actions hosted runner CIDRs from ${var.github_meta_api_url}"
}

resource "terraform_data" "sync_github_actions_runner_items" {
  count = var.enable_github_actions_allowlist ? 1 : 0

  triggers_replace = [
    cloudflare_list.github_actions_runners[0].id,
    local.github_actions_runner_items_hash,
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/sh", "-c"]

    command = <<-EOT
      set -eu

      payload_file="$(mktemp)"
      response_file="$(mktemp)"
      status_file="$(mktemp)"
      cleanup() {
        rm -f "$payload_file" "$response_file" "$status_file"
      }
      trap cleanup EXIT

      python3 - "$payload_file" <<'PY'
import json
import os
import sys
import urllib.request

payload_path = sys.argv[1]
meta_url = os.environ.get("GITHUB_META_API_URL", "").strip()
api_version = os.environ.get("GITHUB_META_API_VERSION", "").strip()

if not meta_url:
    raise SystemExit("GITHUB_META_API_URL is required.")

request = urllib.request.Request(
    meta_url,
    headers={
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": api_version,
    },
)
with urllib.request.urlopen(request, timeout=30) as response:
    data = json.load(response)

items = []
for cidr in data.get("actions", []):
    normalized = str(cidr).strip()
    if not normalized:
        continue
    items.append(
        {
            "ip": normalized,
            "comment": "GitHub Actions hosted runner CIDR",
        }
    )

with open(payload_path, "w", encoding="utf-8") as payload_file:
    json.dump(items, payload_file, separators=(",", ":"))
PY

      if [ ! -s "$payload_file" ]; then
        echo "GitHub Actions CIDR payload is empty."
        exit 1
      fi

      if [ "$(cat "$payload_file")" = "[]" ]; then
        echo "GitHub Actions CIDR payload resolved to an empty list."
        exit 1
      fi

      update_status="$(curl -sS -o "$response_file" -w "%%{http_code}" \
        --request PUT \
        --header "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        --header "Content-Type: application/json" \
        --data @"$payload_file" \
        "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/rules/lists/$CLOUDFLARE_LIST_ID/items")"

      case "$update_status" in
        2??) ;;
        *)
          echo "Cloudflare list update failed with HTTP $update_status"
          cat "$response_file"
          exit 1
          ;;
      esac

      if ! grep -Eq '"success"[[:space:]]*:[[:space:]]*true' "$response_file"; then
        echo "Cloudflare list update response did not report success=true."
        cat "$response_file"
        exit 1
      fi

      operation_id="$(python3 - "$response_file" <<'PY'
import json,sys
with open(sys.argv[1], "r", encoding="utf-8") as f:
    payload = json.load(f)
print(((payload.get("result") or {}).get("operation_id") or "").strip())
PY
)"

      if [ -z "$operation_id" ]; then
        echo "Cloudflare list update response did not include operation_id."
        cat "$response_file"
        exit 1
      fi

      attempt=1
      while [ "$attempt" -le "$CLOUDFLARE_LIST_BULK_POLL_MAX_ATTEMPTS" ]; do
        bulk_status="$(curl -sS -o "$status_file" -w "%%{http_code}" \
          --header "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
          --header "Content-Type: application/json" \
          "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/rules/lists/bulk_operations/$operation_id")"

        case "$bulk_status" in
          2??) ;;
          *)
            echo "Cloudflare bulk operation status call failed with HTTP $bulk_status (attempt $attempt)."
            cat "$status_file"
            exit 1
            ;;
        esac

        op_state="$(python3 - "$status_file" <<'PY'
import json,sys
with open(sys.argv[1], "r", encoding="utf-8") as f:
    payload = json.load(f)
result = payload.get("result") or {}
print(str(result.get("status") or "").strip().lower())
PY
)"

        case "$op_state" in
          completed|complete|done)
            exit 0
            ;;
          failed|failure|error|errored)
            echo "Cloudflare bulk list operation failed."
            cat "$status_file"
            exit 1
            ;;
        esac

        sleep "$CLOUDFLARE_LIST_BULK_POLL_INTERVAL_SECONDS"
        attempt=$((attempt + 1))
      done

      echo "Timed out waiting for Cloudflare bulk list operation to finish."
      cat "$status_file"
      exit 1
    EOT

    environment = {
      CLOUDFLARE_API_TOKEN                      = var.cloudflare_token
      CLOUDFLARE_ACCOUNT_ID                     = var.cloudflare_account_id
      CLOUDFLARE_LIST_ID                        = cloudflare_list.github_actions_runners[0].id
      CLOUDFLARE_LIST_BULK_POLL_INTERVAL_SECONDS = tostring(var.cloudflare_list_bulk_poll_interval_seconds)
      CLOUDFLARE_LIST_BULK_POLL_MAX_ATTEMPTS    = tostring(var.cloudflare_list_bulk_poll_max_attempts)
      GITHUB_META_API_URL                       = var.github_meta_api_url
      GITHUB_META_API_VERSION                   = var.github_meta_api_version
    }
  }
}

resource "terraform_data" "upsert_github_actions_rate_limit_bypass_rule" {
  count = var.enable_github_actions_allowlist && var.enable_github_actions_rate_limit_bypass_rule ? 1 : 0

  triggers_replace = [
    local.github_actions_runner_items_hash,
    local.github_actions_rate_limit_bypass_expression,
    var.cloudflare_zone_id,
  ]

  depends_on = [terraform_data.sync_github_actions_runner_items]

  provisioner "local-exec" {
    interpreter = ["/bin/sh", "-c"]

    command = <<-EOT
      set -eu

      python3 - <<'PY'
import json
import os
import urllib.error
import urllib.request

api_base = "https://api.cloudflare.com/client/v4"
zone_id = os.environ.get("CLOUDFLARE_ZONE_ID", "").strip()
token = os.environ.get("CLOUDFLARE_API_TOKEN", "").strip()
expression = os.environ.get("GITHUB_ACTIONS_BYPASS_EXPRESSION", "").strip()

if not zone_id:
    raise SystemExit("CLOUDFLARE_ZONE_ID is required.")
if not token:
    raise SystemExit("CLOUDFLARE_API_TOKEN is required.")
if not expression:
    raise SystemExit("GITHUB_ACTIONS_BYPASS_EXPRESSION is required.")

rule_ref = "skip_rate_limit_for_github_actions_apps_api"
rule_payload = {
    "ref": rule_ref,
    "description": "Bypass Cloudflare firewall and rate-limiting checks for GitHub Actions app registration API calls.",
    "expression": expression,
    "action": "skip",
    "enabled": True,
    "action_parameters": {
        "ruleset": "current",
        "phases": [
            "http_request_firewall_managed",
            "http_request_sbfm",
            "http_ratelimit",
        ],
        "products": [
            "bic",
            "hot",
            "rateLimit",
            "securityLevel",
            "uaBlock",
            "waf",
            "zoneLockdown",
        ],
    },
}

entrypoint_url = f"{api_base}/zones/{zone_id}/rulesets/phases/http_request_firewall_custom/entrypoint"
headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json",
}

def request_json(method: str, url: str, payload=None):
    body = None
    if payload is not None:
        body = json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(url, data=body, method=method, headers=headers)
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            raw = response.read().decode("utf-8")
            return response.getcode(), json.loads(raw) if raw else {}
    except urllib.error.HTTPError as error:
        raw = error.read().decode("utf-8")
        parsed = {}
        try:
            parsed = json.loads(raw) if raw else {}
        except json.JSONDecodeError:
            parsed = {"raw": raw}
        return error.code, parsed

status, entrypoint = request_json("GET", entrypoint_url)

if status == 404:
    create_payload = {
        "name": "default",
        "description": "Zone-level custom firewall entrypoint managed by Terraform.",
        "kind": "zone",
        "phase": "http_request_firewall_custom",
        "rules": [rule_payload],
    }
    create_status, create_result = request_json("PUT", entrypoint_url, create_payload)
    if create_status < 200 or create_status >= 300 or not create_result.get("success", False):
        raise SystemExit(
            f"Failed to create firewall custom entrypoint ruleset. HTTP {create_status}: {json.dumps(create_result)}"
        )
    raise SystemExit(0)

if status < 200 or status >= 300 or not entrypoint.get("success", False):
    raise SystemExit(
        f"Failed to fetch firewall custom entrypoint ruleset. HTTP {status}: {json.dumps(entrypoint)}"
    )

entrypoint_result = entrypoint.get("result") or {}
ruleset_id = str(entrypoint_result.get("id") or "").strip()
if not ruleset_id:
    raise SystemExit("Cloudflare entrypoint response did not include ruleset id.")

existing_rule = None
first_rule_id = ""
first_other_rule_id = ""
for candidate in entrypoint_result.get("rules") or []:
    candidate_id = str(candidate.get("id") or "").strip()
    if not first_rule_id and candidate_id:
        first_rule_id = candidate_id
    if str(candidate.get("ref") or "").strip() == rule_ref:
        existing_rule = candidate
        continue
    if not first_other_rule_id and candidate_id:
        first_other_rule_id = candidate_id

if existing_rule and str(existing_rule.get("id") or "").strip():
    rule_id = str(existing_rule.get("id")).strip()
    patch_url = f"{api_base}/zones/{zone_id}/rulesets/{ruleset_id}/rules/{rule_id}"
    patch_payload = dict(rule_payload)
    if first_other_rule_id:
        patch_payload["position"] = {"before": first_other_rule_id}
    patch_status, patch_result = request_json("PATCH", patch_url, patch_payload)
    if patch_status < 200 or patch_status >= 300 or not patch_result.get("success", False):
        raise SystemExit(
            f"Failed to update GitHub Actions bypass rule. HTTP {patch_status}: {json.dumps(patch_result)}"
        )
else:
    create_rule_url = f"{api_base}/zones/{zone_id}/rulesets/{ruleset_id}/rules"
    create_payload = dict(rule_payload)
    if first_rule_id:
        create_payload["position"] = {"before": first_rule_id}
    create_rule_status, create_rule_result = request_json("POST", create_rule_url, create_payload)
    if create_rule_status < 200 or create_rule_status >= 300 or not create_rule_result.get("success", False):
        raise SystemExit(
            f"Failed to add GitHub Actions bypass rule. HTTP {create_rule_status}: {json.dumps(create_rule_result)}"
        )
PY
    EOT

    environment = {
      CLOUDFLARE_API_TOKEN            = var.cloudflare_token
      CLOUDFLARE_ZONE_ID              = var.cloudflare_zone_id
      GITHUB_ACTIONS_BYPASS_EXPRESSION = local.github_actions_rate_limit_bypass_expression
    }
  }
}

*/
