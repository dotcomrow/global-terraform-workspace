provider "google" {
  project = var.project
  region  = var.region
  credentials = file(var.credentials_file) 
}

module "projects" {
  source = "./modules/projects"
  project_name = "products-domain"
  gcp_org_id = var.gcp_org_id
  # apis = var.apis
}