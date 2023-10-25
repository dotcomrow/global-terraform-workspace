variable "region" {
  description = "The region to deploy resources"
  type        = string
}

variable "gcp_org_id" {
  description = "The GCP organization id"
  type        = string
}

variable "billing_account" {
  description = "The billing account id"
  type        = string
}

variable "suffix" {
  description = "The suffix to append to project names"
  type        = string
}

variable "bigquery_secret" {
  description = "Bigquery secret to use for the service account"
  type        = string
  nullable = false
}

variable "python_session_secret" {
  description = "Python session secret to use for the service account"
  type        = string
  nullable = false
}

variable "common_project_id" {
  description = "value of common project id"
  type        = string
  nullable = false
}

variable "audience" {
  description = "audience for the service account"
  type        = string
  nullable = false
}

variable "config_security_group" {
  description = "security group for configuration"
  type        = string
  nullable = false
}

variable "domain" {
  description = "domain hosted in cloudflare"
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

