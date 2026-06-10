locals {
  tunnel_secret_override   = trimspace(var.secret)
  tunnel_secret_effective  = local.tunnel_secret_override != "" ? local.tunnel_secret_override : try(random_bytes.tunnel_secret[0].base64, "")
  tunnel_dns_record_name   = trimspace(var.dns_record_name)
  tunnel_domain           = trim(var.domain, ".")
  public_hostname_input   = trimspace(var.public_hostname)
  computed_public_hostname = local.public_hostname_input != "" ? local.public_hostname_input : (
    local.tunnel_dns_record_name == "@" ? local.tunnel_domain : "${local.tunnel_dns_record_name}.${local.tunnel_domain}"
  )
  tunnel_public_hostname   = local.computed_public_hostname
  tunnel_service          = trimspace(var.service)
  proxied_default         = var.proxied
  gcp_secret_name_input   = trimspace(var.gcp_secret_id)
  gcp_secret_name_slug    = join("-", regexall("[a-z0-9_-]+", lower(trimspace(var.name))))
  gcp_secret_name         = local.gcp_secret_name_input != "" ? local.gcp_secret_name_input : format("cloudflare-tunnel-%s-token", local.gcp_secret_name_slug)
  vault_sync_service_name  = trimspace(var.vault_sync_service_name) != "" ? trimspace(var.vault_sync_service_name) : "vault-sync-run-container"
  vault_sync_service_region = trimspace(var.vault_sync_service_region)
  vault_sync_event_url_secret_name = trimspace(var.vault_sync_event_url_secret_name)
  vault_sync_event_token_secret_name = trimspace(var.vault_sync_event_token_secret_name)
  vault_sync_event_url    = trimspace(var.vault_sync_event_url)
  vault_sync_event_fallback_sync_all = var.vault_sync_event_fallback_sync_all
  vault_sync_event_url_env  = local.vault_sync_event_url != "" ? { VAULT_SYNC_EVENT_URL = local.vault_sync_event_url } : {}
  vault_sync_event_token_env = var.vault_sync_event_token != "" ? { VAULT_SYNC_EVENT_TOKEN = var.vault_sync_event_token } : {}
  vault_sync_service_name_env = local.vault_sync_service_name != "" ? { VAULT_SYNC_SERVICE_NAME = local.vault_sync_service_name } : {}
  vault_sync_service_region_env = local.vault_sync_service_region != "" ? { VAULT_SYNC_SERVICE_REGION = local.vault_sync_service_region } : {}
  vault_sync_event_url_secret_name_env = local.vault_sync_event_url_secret_name != "" ? { VAULT_SYNC_EVENT_URL_SECRET_NAME = local.vault_sync_event_url_secret_name } : {}
  vault_sync_event_token_secret_name_env = local.vault_sync_event_token_secret_name != "" ? { VAULT_SYNC_EVENT_TOKEN_SECRET_NAME = local.vault_sync_event_token_secret_name } : {}
  emit_tunnel_secret_events = var.emit_tunnel_secret_sync_events
}

resource "random_bytes" "tunnel_secret" {
  count       = local.tunnel_secret_override == "" ? 1 : 0
  length      = 32
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "this" {
  account_id = var.cloudflare_account_id
  name       = trimspace(var.name)
  secret     = local.tunnel_secret_effective
}

resource "cloudflare_record" "this" {
  zone_id = var.cloudflare_zone_id
  name    = local.tunnel_dns_record_name
  type    = "CNAME"
  content = cloudflare_zero_trust_tunnel_cloudflared.this.cname
  proxied = local.proxied_default
  ttl     = 1
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "this" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.this.id

  lifecycle {
    precondition {
      condition     = local.tunnel_public_hostname != ""
      error_message = "Either public_hostname must be set on the tunnel entry, or domain must be set so it can be derived."
    }
  }

  config {
    ingress_rule {
      hostname = local.tunnel_public_hostname
      service  = local.tunnel_service
    }

    ingress_rule {
      service = "http_status:404"
    }
  }

  depends_on = [cloudflare_record.this]
}

resource "google_secret_manager_secret" "tunnel_token" {
  count    = var.create_gcp_secret ? 1 : 0
  project  = var.project_id
  secret_id = local.gcp_secret_name

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "tunnel_token" {
  count       = var.create_gcp_secret ? 1 : 0
  secret      = google_secret_manager_secret.tunnel_token[0].id
  secret_data = cloudflare_zero_trust_tunnel_cloudflared.this.tunnel_token
}

resource "null_resource" "emit_tunnel_secret_sync_event" {
  count = (var.create_gcp_secret && local.emit_tunnel_secret_events) ? 1 : 0

  depends_on = [google_secret_manager_secret_version.tunnel_token]

  triggers = {
    version_id = google_secret_manager_secret_version.tunnel_token[0].id
    emit       = tostring(local.emit_tunnel_secret_events)
  }

  provisioner "local-exec" {
      environment = merge(
      {
        GCP_PROJECT_ID                      = var.project_id
        VAULT_SYNC_EVENT_FALLBACK_SYNC_ALL   = var.vault_sync_event_fallback_sync_all ? "true" : "false"
        GOOGLE_CREDENTIALS_JSON              = var.google_credentials_json
      },
      local.vault_sync_event_url_env,
      local.vault_sync_event_token_env,
      local.vault_sync_service_name_env,
      local.vault_sync_service_region_env,
      local.vault_sync_event_url_secret_name_env,
      local.vault_sync_event_token_secret_name_env,
    )

    command = <<-EOT
      set -eu

      : "$${VAULT_SYNC_EVENT_URL:=}"
      : "$${VAULT_SYNC_EVENT_TOKEN:=}"
      : "$${VAULT_SYNC_SERVICE_NAME:=}"
      : "$${VAULT_SYNC_SERVICE_REGION:=}"
      : "$${VAULT_SYNC_EVENT_URL_SECRET_NAME:=vault-sync-event-url}"
      : "$${VAULT_SYNC_EVENT_TOKEN_SECRET_NAME:=vault-sync-event-token}"
      : "$${VAULT_SYNC_EVENT_FALLBACK_SYNC_ALL:=false}"

      trim() {
        printf '%s' "$${1}" | tr -d '\r\n' | sed 's/^\\s*//;s/\\s*$//'
      }

      GCP_CRED_FILE=""
      cleanup_gcp_credentials() {
        if [ -n "$${GCP_CRED_FILE}" ] && [ -f "$${GCP_CRED_FILE}" ]; then
          rm -f "$${GCP_CRED_FILE}"
        fi
      }
      trap cleanup_gcp_credentials EXIT INT TERM

      if [ -n "$${GOOGLE_CREDENTIALS_JSON}" ] && command -v gcloud >/dev/null 2>&1; then
        GCP_CRED_FILE="$(mktemp)"
        printf '%s' "$${GOOGLE_CREDENTIALS_JSON}" > "$${GCP_CRED_FILE}"
        gcloud auth activate-service-account --key-file="$${GCP_CRED_FILE}" >/tmp/gcloud-auth.log || true
        gcloud config set project "$${GCP_PROJECT_ID}" >/tmp/gcloud-config.log || true
        export GOOGLE_APPLICATION_CREDENTIALS="$${GCP_CRED_FILE}"
      fi

      vault_sync_service_name="$${VAULT_SYNC_SERVICE_NAME:-}"
      vault_sync_service_region="$${VAULT_SYNC_SERVICE_REGION:-}"
      vault_sync_event_url_secret_name="$${VAULT_SYNC_EVENT_URL_SECRET_NAME:-vault-sync-event-url}"
      vault_sync_event_token_secret_name="$${VAULT_SYNC_EVENT_TOKEN_SECRET_NAME:-vault-sync-event-token}"

      discover_event_url() {
        local project="$${1:-}"
        local region="$${2:-}"
        local service="$${3:-}"
        local url_secret_name="$${4:-$vault_sync_event_url_secret_name}"
        local discovered=""

        if [ -n "$${service}" ] && [ -n "$${project}" ] && command -v gcloud >/dev/null 2>&1; then
          if [ -n "$${region}" ]; then
            discovered="$$(gcloud run services describe "$${service}" \
              --project="$${project}" --region="$${region}" --platform=managed \
              --format='value(status.url)' 2>/dev/null || true)"
          else
            discovered="$$(gcloud run services list --platform=managed \
              --project="$${project}" --filter="metadata.name=$${service}" \
              --format='value(status.url)' 2>/dev/null | head -n1 || true)"
          fi
        fi

        if [ -z "$${discovered}" ] && [ -n "$${project}" ] && [ -n "$${url_secret_name}" ] && command -v gcloud >/dev/null 2>&1; then
          discovered="$$(gcloud secrets versions access latest \
            --project="$${project}" --secret="$${url_secret_name}" 2>/dev/null | tr -d '\r\n' || true)"
        fi

        trim "$${discovered}"
      }

      discover_event_token() {
        local project="$${1:-}"
        local audience="$${2:-}"
        local token_secret_name="$${3:-$vault_sync_event_token_secret_name}"
        local discovered=""

        if [ -n "$${audience}" ] && command -v gcloud >/dev/null 2>&1; then
          discovered="$$(gcloud auth print-identity-token --audiences "$${audience}" 2>/dev/null || true)"
        fi

        if [ -z "$${discovered}" ] && [ -n "$${audience}" ] && command -v curl >/dev/null 2>&1; then
          discovered="$$(curl -sS --fail --show-error \
            -H 'Metadata-Flavor: Google' \
            "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/identity?audience=$${audience}" 2>/dev/null || true)"
        fi

        if [ -z "$${discovered}" ] && [ -n "$${project}" ] && [ -n "$${token_secret_name}" ] && command -v gcloud >/dev/null 2>&1; then
          discovered="$$(gcloud secrets versions access latest \
            --project="$${project}" --secret="$${token_secret_name}" 2>/dev/null | tr -d '\r\n' || true)"
        fi

        trim "$${discovered}"
      }

      run_sync_all() {
        local target="$${1:-$${sync_all_url}}"
        local sync_all_status

        if [ -n "$${VAULT_SYNC_EVENT_TOKEN}" ]; then
          sync_all_status="$$(curl --silent --show-error --location --request POST \
            --header 'Content-Type: application/json' \
            --header "Authorization: Bearer $${VAULT_SYNC_EVENT_TOKEN}" \
            --write-out '%%{http_code}' \
            --output "$${response_file}" \
            "$${target}" || echo 000)"
        else
          sync_all_status="$$(curl --silent --show-error --location --request POST \
            --header 'Content-Type: application/json' \
            --write-out '%%{http_code}' \
            --output "$${response_file}" \
            "$${target}" || echo 000)"
        fi

        echo "vault sync-all status=$${sync_all_status}"
        if [ "$${sync_all_status}" -ne 200 ] && [ "$${sync_all_status}" -ne 204 ]; then
          echo "vault sync-all failed with status $${sync_all_status}" >&2
          return 1
        fi

        echo "vault sync-all completed."
        return 0
      }

      audit_payload="$(cat <<JSON
      {
        "protoPayload": {
          "methodName": "google.cloud.secretmanager.v1.SecretManagerService.AddSecretVersion",
          "resourceName": "${google_secret_manager_secret_version.tunnel_token[0].name}",
          "serviceName": "secretmanager.googleapis.com"
        }
      }
      JSON
      )"

      audit_payload_b64="$(printf '%s' "$${audit_payload}" | base64 | tr -d '\n')"

      payload="$(cat <<JSON
      {
        "message": {
          "messageId": "${google_secret_manager_secret_version.tunnel_token[0].id}",
          "publishTime": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
          "data": "$${audit_payload_b64}"
        },
        "data": {
          "protoPayload": {
            "methodName": "google.cloud.secretmanager.v1.SecretManagerService.AddSecretVersion",
            "resourceName": "${google_secret_manager_secret_version.tunnel_token[0].name}",
            "serviceName": "secretmanager.googleapis.com"
          }
        },
        "protoPayload": {
          "methodName": "google.cloud.secretmanager.v1.SecretManagerService.AddSecretVersion",
          "resourceName": "${google_secret_manager_secret_version.tunnel_token[0].name}",
          "serviceName": "secretmanager.googleapis.com"
        }
      }
      JSON
      )"

      echo "Posting synthetic vault-sync event for secret version: ${google_secret_manager_secret_version.tunnel_token[0].name}"

      response_file="$$(mktemp)"
      event_url=""
      event_url_source="unset"
      token_source="unset"

      if [ -n "$${VAULT_SYNC_EVENT_URL}" ]; then
        event_url="$$(trim "$${VAULT_SYNC_EVENT_URL}")"
        event_url_source="process-env"
      fi

      if [ -z "$${event_url}" ] && [ -n "$${GCP_PROJECT_ID}" ] && command -v gcloud >/dev/null 2>&1; then
        event_url="$$(discover_event_url "$${GCP_PROJECT_ID}" "$${vault_sync_service_region}" "$${vault_sync_service_name}" "$${vault_sync_event_url_secret_name}")"
        event_url_source="gcloud"
      fi

      event_url="$$(trim "$${event_url}")"
      event_url="$${event_url%/}"
      if [ -n "$${event_url}" ] && [ -z "$${VAULT_SYNC_EVENT_TOKEN}" ] && command -v gcloud >/dev/null 2>&1; then
        VAULT_SYNC_EVENT_TOKEN="$$(discover_event_token "$${GCP_PROJECT_ID}" "$${event_url}")"
        token_source="gcloud"
      elif [ -n "$${VAULT_SYNC_EVENT_TOKEN}" ]; then
        token_source="process-env"
      else
        token_source="missing"
      fi

      if [ -z "$${event_url}" ]; then
        echo "vault sync event URL could not be resolved. Set VAULT_SYNC_EVENT_URL or provide gcloud-accessible Vault sync service/secret names." >&2
        rm -f "$${response_file}"
        exit 1
      fi
      echo "vault sync event target=$${event_url} source=$${event_url_source:-unknown} token_source=$${token_source:-env-or-secret}"

      sync_all_url="$${event_url}/sync-all"

      if [ -n "$${VAULT_SYNC_EVENT_TOKEN}" ]; then
        status="$$(curl --silent --show-error --location --request POST \
          --header 'Content-Type: application/json' \
          --header "Authorization: Bearer $${VAULT_SYNC_EVENT_TOKEN}" \
          --data "$${payload}" \
          --write-out '%%{http_code}' \
          --output "$${response_file}" \
          "$${event_url}" || echo 000)"
      else
        status="$$(curl --silent --show-error --location --request POST \
          --header 'Content-Type: application/json' \
          --data "$${payload}" \
          --write-out '%%{http_code}' \
          --output "$${response_file}" \
          "$${event_url}" || echo 000)"
      fi

      echo "vault sync event response status=$${status}"
      if [ -s "$${response_file}" ]; then
        echo "vault sync event response body: $$(cat "$${response_file}")"
      else
        echo "vault sync event response body: <empty>"
      fi

      if [ "$${status}" -ne 200 ] && [ "$${status}" -ne 204 ]; then
        echo "vault sync event failed with status $${status}" >&2
        if [ "$${VAULT_SYNC_EVENT_FALLBACK_SYNC_ALL}" = "true" ]; then
          echo "Attempting fallback sync-all to recover..."
          run_sync_all "$${sync_all_url}" || {
            rm -f "$${response_file}"
            exit 1
          }
          rm -f "$${response_file}"
          exit 0
        fi

        rm -f "$${response_file}"
        exit 1
      fi

      if [ "$${VAULT_SYNC_EVENT_FALLBACK_SYNC_ALL}" = "true" ]; then
        echo "Event call succeeded; running sync-all for deterministic reconciliation."
        run_sync_all "$${sync_all_url}" || {
          rm -f "$${response_file}"
          exit 1
        }
      fi

      rm -f "$${response_file}"
    EOT
  }
}
