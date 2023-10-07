variable "common_project_name" {
  nullable = false
  description = "The name of project to store global bigquery service account"
  type = string
  default = ""
}

variable "region" {
  description = "The region to deploy resources"
  type        = string
  nullable = false
  default = ""
}

variable "gcp_org_id" {
  description = "The GCP organization id"
  type        = string
  nullable = false
  default = ""
}

variable "billing_account" {
  description = "The billing account id"
  type        = string
  nullable = false
  default = ""
}