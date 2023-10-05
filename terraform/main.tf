provider "google" {
  project = var.project
  region  = var.region
  credentials = file(var.credentials_file) 
}

# resource "null_resource" "loop_list" {
#   provisioner "local-exec" {
#     command     = "for item in $REPOS; do git clone git@github.com:<ORGANIZATION_ID>/$item.git; done"
#     environment = { REPOS = join(" ", var.repositories) }
#   }
# }

# module "products" {
#   source = "./modules/projects"
#   project_name = "products-domain"
#   gcp_org_id = var.gcp_org_id
#   # apis = var.apis
#   # project_module = "git@github.com:dotcomrow/products-terraform-workspace.git//terraform"
# }

# module "carts" {
#   source = "./modules/projects"
#   project_name = "carts-domain"
#   gcp_org_id = var.gcp_org_id
#   # apis = var.apis
#   # project_module = "git@github.com:dotcomrow/cart-terraform-workspace.git//terraform"
# }

# module "orders" {
#   source = "./modules/projects"
#   project_name = "orders-domain"
#   gcp_org_id = var.gcp_org_id
#   # apis = var.apis
#   # project_module = "git@github.com:dotcomrow/orders-terraform-workspace.git//terraform"
# }

module "orders" {
  source  = "app.terraform.io/dotcomrow/orders/google"
  version = "> 1.0.0"
  project_name = "ordersDomain"
  gcp_org_id = var.gcp_org_id
}

module "cart" {
  source  = "app.terraform.io/dotcomrow/cart/google"
  version = "> 1.0.0"
  project_name = "cartsDomain"
  gcp_org_id = var.gcp_org_id
}

module "products" {
  source  = "app.terraform.io/dotcomrow/products/google"
  version = "> 1.0.0"
  project_name = "productsDomain"
  gcp_org_id = var.gcp_org_id
}