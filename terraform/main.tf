provider "google" {
  region  = var.region
  credentials = file(var.credentials_file) 
}

resource "google_project_service" "project_service" {
  count = length(var.apis)

  disable_dependent_services = true
  project = google_project.project.project_id
  service = var.apis[count.index]
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
  project_name = "ordersdomn"
  gcp_org_id = var.gcp_org_id
  billing_account = "${var.billing_account}"
}

module "cart" {
  source  = "app.terraform.io/dotcomrow/cart/google"
  version = "> 1.0.0"
  project_name = "cartsdomn"
  gcp_org_id = var.gcp_org_id
  billing_account ="${var.billing_account}"
}

module "products" {
  source  = "app.terraform.io/dotcomrow/products/google"
  version = "> 1.0.0"
  project_name = "productsdomn"
  gcp_org_id = var.gcp_org_id
  billing_account = "${var.billing_account}"
}