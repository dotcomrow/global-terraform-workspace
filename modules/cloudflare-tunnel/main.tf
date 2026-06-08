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
  gcp_secret_name_slug    = regexreplace(lower(trimspace(var.name)), "[^a-z0-9_-]", "-")
  gcp_secret_name         = local.gcp_secret_name_input != "" ? local.gcp_secret_name_input : format("cloudflare-tunnel-%s-token", local.gcp_secret_name_slug)
}

resource "random_bytes" "tunnel_secret" {
  count       = local.tunnel_secret_override == "" ? 1 : 0
  byte_length = 32
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "this" {
  account_id = var.cloudflare_account_id
  name       = trimspace(var.name)
  secret     = local.tunnel_secret_effective
}

resource "cloudflare_dns_record" "this" {
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

  config = {
    ingress = [
      {
        hostname = local.tunnel_public_hostname
        service  = local.tunnel_service
      },
      {
        service = "http_status:404"
      },
    ]
  }

  depends_on = [cloudflare_dns_record.this]
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "this" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.this.id
}

resource "google_secret_manager_secret" "tunnel_token" {
  count    = var.create_gcp_secret ? 1 : 0
  project  = var.project_id
  secret_id = local.gcp_secret_name

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "tunnel_token" {
  count       = var.create_gcp_secret ? 1 : 0
  secret      = google_secret_manager_secret.tunnel_token[0].id
  secret_data = data.cloudflare_zero_trust_tunnel_cloudflared_token.this.token
}
