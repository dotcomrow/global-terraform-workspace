variable "project_name" {
    default = "<YOUR-PROJECT-ID>"
}

variable "region" {
    default = "<REGION>"
}

variable credentials_file {
    default = "google.key"
}

variable gcp_org_id {
    default = "<GCP_ORGANIZATION_ID>" 
}

variable "apis" {
  description = "The list of apis to enable"  
  type        = list(string)
  default     = [
    "iam.googleapis.com", 
    "cloudresourcemanager.googleapis.com", 
    "bigquery.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudbilling.googleapis.com",
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "containerregistry.googleapis.com",
    "secretmanager.googleapis.com"
  ]
}

variable "billing_account" {
  description = "The billing account id"
  type        = string
  default     = "0126C7-7C7247-4B8FBB"
}