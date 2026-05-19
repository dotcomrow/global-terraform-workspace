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

  github_actions_rate_limit_bypass_expression = format(
    "(http.host eq %q and starts_with(http.request.uri.path, %q) and ip.src in %s)",
    var.github_actions_bypass_host,
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

resource "cloudflare_ruleset" "github_actions_rate_limit_bypass" {
  count = var.enable_github_actions_allowlist && var.enable_github_actions_rate_limit_bypass_rule ? 1 : 0

  zone_id     = var.cloudflare_zone_id
  name        = "GitHub Actions rate limit bypass"
  description = "Skips rate limiting for GitHub Actions traffic targeting auth-gateway app management endpoints."
  kind        = "zone"
  phase       = "http_request_firewall_custom"
  depends_on  = [terraform_data.sync_github_actions_runner_items]

  rules {
    ref         = "skip_rate_limit_for_github_actions_apps_api"
    description = "Skip rate limiting for GitHub Actions app registration API calls."
    expression  = local.github_actions_rate_limit_bypass_expression
    action      = "skip"
    enabled     = true

    action_parameters {
      products = ["rateLimit"]
    }
  }
}
