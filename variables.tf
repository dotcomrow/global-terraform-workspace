variable "common_project_name" {
  description = "The name of project to store global bigquery service account"
  type = string
}

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
