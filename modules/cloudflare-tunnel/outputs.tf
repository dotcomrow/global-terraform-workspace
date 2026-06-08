output "tunnel_id" {
  description = "Cloudflare tunnel ID."
  value       = cloudflare_zero_trust_tunnel_cloudflared.this.id
}

output "tunnel_name" {
  description = "Cloudflare tunnel name."
  value       = cloudflare_zero_trust_tunnel_cloudflared.this.name
}

output "tunnel_cname" {
  description = "Tunnel CNAME target."
  value       = cloudflare_zero_trust_tunnel_cloudflared.this.cname
}

output "dns_record_name" {
  description = "DNS record name managed for this tunnel."
  value       = cloudflare_record.this.name
}

output "public_hostname" {
  description = "Tunnel ingress public hostname."
  value       = local.tunnel_public_hostname
}

output "tunnel_service" {
  description = "Tunnel origin service."
  value       = local.tunnel_service
}

output "tunnel_token" {
  description = "Cloudflared run token."
  value       = cloudflare_zero_trust_tunnel_cloudflared.this.tunnel_token
  sensitive   = true
}

output "gcp_secret_id" {
  description = "Secret Manager secret ID name used for the tunnel token."
  value = var.create_gcp_secret ? try(google_secret_manager_secret.tunnel_token[0].secret_id, null) : null
}

output "gcp_secret_version_id" {
  description = "Secret Manager secret version resource ID."
  value = var.create_gcp_secret ? try(google_secret_manager_secret_version.tunnel_token[0].id, null) : null
}

output "gcp_secret_created" {
  description = "Whether Google Secret Manager secret was created for this tunnel."
  value       = var.create_gcp_secret
}
