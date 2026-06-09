variable "cloudflare_account_id" {
  description = "Cloudflare account ID used for tunnel resources."
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID used for tunnel DNS record."
  type        = string
}

variable "project_id" {
  description = "GCP project ID for storing tunnel tokens as Secret Manager secrets."
  type        = string
}

variable "name" {
  description = "Tunnel name."
  type        = string

  validation {
    condition     = trimspace(var.name) != ""
    error_message = "name must not be empty."
  }
}

variable "dns_record_name" {
  description = "CNAME record name (relative to zone), for example myapp."
  type        = string

  validation {
    condition     = trimspace(var.dns_record_name) != ""
    error_message = "dns_record_name must not be empty."
  }
}

variable "public_hostname" {
  description = "Optional override for the public hostname used in tunnel ingress."
  type        = string
  default     = ""
}

variable "domain" {
  description = "Zone domain used to build public hostname when public_hostname is not set."
  type        = string
  default     = ""
}

variable "service" {
  description = "Origin service URL for ingress, e.g. http://127.0.0.1:8080."
  type        = string

  validation {
    condition     = can(regex("^https?://", trimspace(var.service)))
    error_message = "service must start with http:// or https://."
  }
}

variable "secret" {
  description = "Optional tunnel secret (base64). If omitted, generated automatically."
  type        = string
  default     = ""
  sensitive   = true
}

variable "create_gcp_secret" {
  description = "Whether to write the tunnel token into Google Secret Manager."
  type        = bool
  default     = true
}

variable "gcp_secret_id" {
  description = "Optional Secret Manager secret ID. If omitted, a derived ID is used."
  type        = string
  default     = ""
}

variable "proxied" {
  description = "Whether the tunnel DNS record is proxied."
  type        = bool
  default     = true
}

variable "emit_tunnel_secret_sync_events" {
  description = "When true, emit a synthetic Vault sync event for each secret version created. Emission also runs automatically when vault_sync_event_url is set."
  type        = bool
  default     = false
}

variable "vault_sync_event_url" {
  description = "Optional webhook URL for synthetic Vault sync events."
  type        = string
  default     = ""

  validation {
    condition     = var.vault_sync_event_url == "" || can(regex("^https://", trimspace(var.vault_sync_event_url)))
    error_message = "vault_sync_event_url must be blank or a valid https URL."
  }
}

variable "vault_sync_event_token" {
  description = "Optional bearer token for vault sync webhook calls."
  type        = string
  sensitive   = true
  default     = ""
}

variable "vault_sync_event_fallback_sync_all" {
  description = "When true, call /sync-all after synthetic event emit."
  type        = bool
  default     = false
}
