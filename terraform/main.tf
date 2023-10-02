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
  project_module = "git@github.com:dotcomrow/products-terraform-workspace.git//terraform"
}

module "carts" {
  source = "./modules/projects"
  project_name = "carts-domain"
  gcp_org_id = var.gcp_org_id
  # apis = var.apis
  project_module = "git@github.com:dotcomrow/cart-terraform-workspace.git//terraform"
}

module "orders" {
  source = "./modules/projects"
  project_name = "orders-domain"
  gcp_org_id = var.gcp_org_id
  # apis = var.apis
  project_module = "git@github.com:dotcomrow/orders-terraform-workspace.git//terraform"
}