provider "google" {
  region  = var.region
  credentials = file(var.credentials_file) 
}

resource "google_project_service" "project_service" {
  count = length(var.apis)

  disable_dependent_services = true
  project = var.project_name
  service = var.apis[count.index]
}

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