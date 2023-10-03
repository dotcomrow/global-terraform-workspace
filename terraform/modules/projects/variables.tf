variable "project_name" {
  description = "The name of the project to create"
  type        = string
}

variable "gcp_org_id" {
  description = "The organization id to create the project under"
  type        = string
}

variable "apis" {
  description = "The list of apis to enable"
  type        = list(string)
  default     = [
    "iam.googleapis.com", 
    "cloudresourcemanager.googleapis.com", 
    "cloudbilling.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerystorage.googleapis.com"
  ]
}
