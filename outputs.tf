output "cloudflare_tunnel_ids" {
  description = "Cloudflare tunnel IDs, keyed by tunnel key."
  value = {
    for k, tunnel in module.cloudflare_tunnel :
    k => tunnel.tunnel_id
  }
}

output "cloudflare_tunnel_names" {
  description = "Cloudflare tunnel names, keyed by tunnel key."
  value = {
    for k, tunnel in module.cloudflare_tunnel :
    k => tunnel.tunnel_name
  }
}

output "cloudflare_tunnel_cnames" {
  description = "Tunnel CNAME targets, keyed by tunnel key."
  value = {
    for k, tunnel in module.cloudflare_tunnel :
    k => tunnel.tunnel_cname
  }
}

output "cloudflare_tunnel_ingress_hosts" {
  description = "Tunnel ingress hostnames, keyed by tunnel key."
  value = {
    for k, tunnel in module.cloudflare_tunnel :
    k => tunnel.public_hostname
  }
}

output "cloudflare_tunnel_services" {
  description = "Tunnel origin services, keyed by tunnel key."
  value = {
    for k, tunnel in module.cloudflare_tunnel :
    k => tunnel.tunnel_service
  }
}

output "cloudflare_tunnel_tokens" {
  description = "Cloudflare tunnel tokens, keyed by tunnel key."
  value = {
    for k, tunnel in module.cloudflare_tunnel :
    k => tunnel.tunnel_token
  }
  sensitive   = true
}

output "cloudflare_tunnel_secret_ids" {
  description = "Google Secret Manager secret IDs for tunnel tokens, keyed by tunnel key."
  value = {
    for k, tunnel in module.cloudflare_tunnel :
    k => tunnel.gcp_secret_id
  }
}

output "cloudflare_tunnel_secret_version_ids" {
  description = "Google Secret Manager secret version IDs for tunnel tokens, keyed by tunnel key."
  value = {
    for k, tunnel in module.cloudflare_tunnel :
    k => tunnel.gcp_secret_version_id
  }
}

output "cloudflare_tunnel_vault_sync_event_urls" {
  description = "Vault-sync webhook URLs configured on each tunnel module instance."
  value = {
    for k, tunnel in module.cloudflare_tunnel :
    k => tunnel.vault_sync_event_url
  }
}

output "cloudflare_tunnel_vault_sync_event_enabled" {
  description = "Whether synthetic vault-sync event emission is enabled per tunnel module instance."
  value = {
    for k, tunnel in module.cloudflare_tunnel :
    k => tunnel.vault_sync_event_enabled
  }
}

output "vault_sync_event_fallback_sync_all" {
  description = "Whether fallback /sync-all behavior is enabled."
  value       = var.vault_sync_event_fallback_sync_all
}

output "cloudflare_tunnel_secret_enabled" {
  description = "Whether Google Secret Manager creation is enabled per tunnel key."
  value = {
    for k, tunnel in module.cloudflare_tunnel :
    k => tunnel.gcp_secret_created
  }
}

output "vault_sync_synthetic_events_enabled" {
  description = "Whether synthetic Vault-sync events are enabled for this workspace."
  value       = var.emit_tunnel_secret_sync_events || trimspace(var.vault_sync_event_url) != ""
}
