provider "google" {
  project = var.project
  region  = var.region
  credentials = file(var.credentials_file) 
}

module "projects" {
  source = "./modules/projects"
  project_name = var.project_name
  gcp_org_id = var.gcp_org_id
  apis = var.apis
}