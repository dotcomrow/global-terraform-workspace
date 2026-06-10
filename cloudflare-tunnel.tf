data "cloudflare_zone" "workspace_zone" {
  zone_id = var.cloudflare_zone_id
}

locals {
  workspace_tunnel_domain = trimspace(var.domain)
  derived_tunnel_domain   = local.workspace_tunnel_domain != "" ? local.workspace_tunnel_domain : trim(data.cloudflare_zone.workspace_zone.name, ".")
}

module "cloudflare_tunnel" {
  for_each = var.cloudflare_tunnels

  source = "./modules/cloudflare-tunnel"

  cloudflare_account_id = var.cloudflare_account_id
  cloudflare_zone_id    = var.cloudflare_zone_id
  project_id           = var.secret_manager_project_id

  name            = each.value.name
  dns_record_name = each.value.dns_record_name
  public_hostname = each.value.public_hostname
  domain          = local.derived_tunnel_domain
  service         = each.value.service
  secret          = each.value.secret
  create_gcp_secret = each.value.create_gcp_secret
  gcp_secret_id     = each.value.gcp_secret_id
  proxied         = each.value.proxied
  emit_tunnel_secret_sync_events      = var.emit_tunnel_secret_sync_events
  vault_sync_grant_invoker_binding    = var.vault_sync_grant_invoker_binding
  vault_sync_event_url                = var.vault_sync_event_url
  vault_sync_event_token              = var.vault_sync_event_token
  google_credentials_json             = var.google_credentials_tunnel_key_json
  vault_sync_service_name             = trimspace(var.vault_sync_service_name) != "" ? trimspace(var.vault_sync_service_name) : "vault-sync-run-container"
  vault_sync_service_region           = trimspace(var.vault_sync_service_region) != "" ? trimspace(var.vault_sync_service_region) : var.region
  vault_sync_service_project          = trimspace(var.vault_sync_service_project) != "" ? trimspace(var.vault_sync_service_project) : var.secret_manager_project_id
  vault_sync_event_url_secret_name    = var.vault_sync_event_url_secret_name
  vault_sync_event_token_secret_name  = var.vault_sync_event_token_secret_name
  vault_sync_event_fallback_sync_all  = var.vault_sync_event_fallback_sync_all
}
