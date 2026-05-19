variable "region" {
  description = "The region to deploy resources"
  type        = string
}

variable "common_project_id" {
  description = "value of common project id"
  type        = string
  nullable = false
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
  default     = true
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
  default     = true
  nullable    = false
}

variable "github_actions_bypass_host" {
  description = "Hostname the GitHub Actions rate-limit bypass rule applies to."
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
