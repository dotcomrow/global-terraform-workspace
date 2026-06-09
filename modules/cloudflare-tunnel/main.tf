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
  vault_sync_event_url    = trimspace(var.vault_sync_event_url)
  emit_tunnel_secret_events = var.emit_tunnel_secret_sync_events || local.vault_sync_event_url != ""
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

  lifecycle {
    precondition {
      condition     = !(var.emit_tunnel_secret_sync_events && trimspace(var.vault_sync_event_url) == "")
      error_message = "vault_sync_event_url must be set when emit_tunnel_secret_sync_events = true."
    }
  }

  triggers = {
    version_id = google_secret_manager_secret_version.tunnel_token[0].id
    event_url  = local.vault_sync_event_url
  }

  provisioner "local-exec" {
    environment = {
      VAULT_SYNC_EVENT_URL   = local.vault_sync_event_url
      VAULT_SYNC_EVENT_TOKEN = var.vault_sync_event_token
    }

    command = <<-EOT
      set -eu

      payload="$(cat <<'JSON'
{
  "protoPayload": {
    "methodName": "google.cloud.secretmanager.v1.SecretManagerService.AddSecretVersion",
    "resourceName": "${google_secret_manager_secret_version.tunnel_token[0].name}"
  }
}
JSON
)"

      echo "Posting synthetic vault-sync event for secret version: ${google_secret_manager_secret_version.tunnel_token[0].name}"

      response_file="$$(mktemp)"

      if [ -n "$${VAULT_SYNC_EVENT_TOKEN}" ]; then
        status="$$(curl --silent --show-error --location --request POST \
          --header "Content-Type: application/json" \
          --header "Authorization: Bearer $${VAULT_SYNC_EVENT_TOKEN}" \
          --data "$${payload}" \
          --write-out '%%{http_code}' \
          --output "$${response_file}" \
          "$${VAULT_SYNC_EVENT_URL}" || echo 000)"
      else
        status="$$(curl --silent --show-error --location --request POST \
          --header "Content-Type: application/json" \
          --data "$${payload}" \
          --write-out '%%{http_code}' \
          --output "$${response_file}" \
          "$${VAULT_SYNC_EVENT_URL}" || echo 000)"
      fi

      echo "vault sync event response status=$${status}"
      if [ -s "$${response_file}" ]; then
        echo "vault sync event response body: $$(cat "$${response_file}")"
      else
        echo "vault sync event response body: <empty>"
      fi

      if [ "$${status}" -ne 200 ] && [ "$${status}" -ne 204 ]; then
        echo "vault sync event failed with status $${status}" >&2
        rm -f "$${response_file}"
        exit 1
      fi

      rm -f "$${response_file}"
    EOT
  }
}
