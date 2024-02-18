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