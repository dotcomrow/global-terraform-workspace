variable "common_project_name" {
  nullable = false
  description = "The name of project to store global bigquery service account"
}

variable "region" {
  description = "The region to deploy resources"
  type        = string
  nullable = false
}

variable gcp_org_id {
  description = "The GCP organization id"
  type        = string
  nullable = false
}

variable "billing_account" {
  description = "The billing account id"
  type        = string
  nullable = false
}