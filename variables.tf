variable "region" {
  description = "The region to deploy resources"
  type        = string
}

variable "google_credentials_tunnel_key_json" {
  description = "Google service account JSON key used for Secret Manager access."
  type        = string
  sensitive   = true
  nullable    = false
}

variable "secret_manager_project_id" {
  description = "Google project id for Secret Manager tunnel tokens."
  type        = string
  nullable = false
}

variable "emit_tunnel_secret_sync_events" {
  description = "Backward-compatible switch for synthetic vault-sync events. Events are emitted when this is true or when a vault_sync_event_url is configured."
  type        = bool
  default     = false
  nullable    = false
}

variable "vault_sync_event_url" {
  description = "Webhook URL for synthetic vault-sync events (for example https://vault-sync-run-container-.../)."
  type        = string
  default     = ""

  validation {
    condition     = var.vault_sync_event_url == "" || can(regex("^https://", trimspace(var.vault_sync_event_url)))
    error_message = "vault_sync_event_url must be blank or a valid https URL."
  }
}

variable "vault_sync_event_token" {
  description = "Optional bearer token for the vault sync webhook."
  type        = string
  sensitive   = true
  default     = ""
}

variable "cloudflare_token" {
  description = "cloudflare token"
  type        = string
  nullable = false
}

variable "cloudflare_account_id" {
  description = "Cloudflare account id"
  type        = string
  nullable = false
}

variable "cloudflare_zone_id" {
  description = "cloudflare worker zone id"
  type        = string
  nullable = false
}

variable "domain" {
  description = "Zone domain used to build tunnel public hostnames (for example, example.com)."
  type        = string
  default     = ""
}

variable "registry_name" {
  description = "registry name"
  type        = string
  nullable = false
}

variable "cloudflare_logs_access_secret" {
  description = "cloudflare logs access secret"
  type        = string
  nullable = false
}

variable "cloudflare_logs_access_key" {
  description = "cloudflare logs access key"
  type        = string
  nullable = false
}

variable "enable_github_actions_allowlist" {
  description = "When true, enables optional GitHub Actions CIDR synchronization into a Cloudflare account list."
  type        = bool
  default     = false
  nullable    = false
}

variable "github_meta_api_url" {
  description = "GitHub metadata endpoint used to retrieve current GitHub Actions runner CIDR ranges."
  type        = string
  default     = "https://api.github.com/meta"
  nullable    = false
}

variable "github_meta_api_version" {
  description = "GitHub API version header used when requesting metadata."
  type        = string
  default     = "2026-03-10"
  nullable    = false
}

variable "github_actions_cloudflare_list_name" {
  description = "Cloudflare account-level list name used to store GitHub Actions runner CIDR ranges."
  type        = string
  default     = "github_actions_runners"
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9_]{1,50}$", var.github_actions_cloudflare_list_name))
    error_message = "github_actions_cloudflare_list_name must match ^[a-z0-9_]{1,50}$."
  }
}

variable "enable_github_actions_rate_limit_bypass_rule" {
  description = "When true, creates a separate custom WAF rule that skips rate limiting for GitHub Actions traffic to the auth-gateway app API path."
  type        = bool
  default     = false
  nullable    = false
}

variable "github_actions_bypass_host" {
  description = "Primary hostname the GitHub Actions bypass rule applies to. auth-origin.suncoast.systems is always included automatically."
  type        = string
  default     = "login.suncoast.systems"
  nullable    = false
}

variable "github_actions_bypass_path_prefix" {
  description = "Path prefix the GitHub Actions rate-limit bypass rule applies to."
  type        = string
  default     = "/v1/apps"
  nullable    = false

  validation {
    condition     = startswith(var.github_actions_bypass_path_prefix, "/")
    error_message = "github_actions_bypass_path_prefix must start with '/'."
  }
}

variable "cloudflare_list_bulk_poll_interval_seconds" {
  description = "Polling interval in seconds when waiting for Cloudflare list bulk operations to finish."
  type        = number
  default     = 5
  nullable    = false

  validation {
    condition     = var.cloudflare_list_bulk_poll_interval_seconds >= 1 && var.cloudflare_list_bulk_poll_interval_seconds <= 60
    error_message = "cloudflare_list_bulk_poll_interval_seconds must be between 1 and 60."
  }
}

variable "cloudflare_list_bulk_poll_max_attempts" {
  description = "Maximum number of status polling attempts for Cloudflare list bulk operations."
  type        = number
  default     = 180
  nullable    = false

  validation {
    condition     = var.cloudflare_list_bulk_poll_max_attempts >= 1 && var.cloudflare_list_bulk_poll_max_attempts <= 720
    error_message = "cloudflare_list_bulk_poll_max_attempts must be between 1 and 720."
  }
}

variable "cloudflare_tunnels" {
  description = "Reusable map of Cloudflare tunnels to create."
  type = map(object({
    name              = string
    dns_record_name   = string
    public_hostname   = optional(string, "")
    service           = string
    secret            = optional(string, "")
    create_gcp_secret = optional(bool, true)
    gcp_secret_id     = optional(string, "")
    proxied           = optional(bool, true)
  }))
  default = {}

  validation {
    condition = alltrue([
      for tunnel in values(var.cloudflare_tunnels) :
      trimspace(tunnel.name) != "" &&
      trimspace(tunnel.dns_record_name) != "" &&
      trimspace(tunnel.service) != "" &&
      can(regex("^https?://", trimspace(tunnel.service)))
    ])
    error_message = "Each tunnel must set name, dns_record_name, and service (service must start with http:// or https://)."
  }

  validation {
    condition = alltrue([
      for key, tunnel in var.cloudflare_tunnels :
      !try(tunnel.create_gcp_secret, true) || (
        trimspace(try(tunnel.gcp_secret_id, "")) == "" ||
        can(regex("^[A-Za-z0-9][A-Za-z0-9_-]{0,254}$", trimspace(try(tunnel.gcp_secret_id, ""))))
      )
    ])
    error_message = "gcp_secret_id must be a valid Secret Manager ID when create_gcp_secret is true."
  }
}
