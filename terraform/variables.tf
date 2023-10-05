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

# variable "repositories" {
#   default = [
#     "products-terraform-workspace", 
#     "cart-terraform-workspace",
#     "orders-terraform-workspace"
#   ]
# }