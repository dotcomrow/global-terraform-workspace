provider "google" {
  project = var.project
  region  = var.region
  credentials = file(var.credentials_file) 
}

module "products" {
  source = "./modules/projects"
  project_name = "products-domain"
  gcp_org_id = var.gcp_org_id
  # apis = var.apis
}

module "carts" {
  source = "./modules/projects"
  project_name = "carts-domain"
  gcp_org_id = var.gcp_org_id
  # apis = var.apis
}

module "orders" {
  source = "./modules/projects"
  project_name = "orders-domain"
  gcp_org_id = var.gcp_org_id
  # apis = var.apis
}