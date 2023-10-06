variable "common_project_name" {
  nullable = false
  description = "The name of project to store global bigquery service account"
}

variable "region" {
    default = "<REGION>"
}

variable gcp_org_id {
    default = "<GCP_ORGANIZATION_ID>" 
}

variable "billing_account" {
  description = "The billing account id"
  type        = string
}