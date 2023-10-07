provider "google" {
  region  = "${var.region}"
}

module "orders" {
  source  = "app.terraform.io/dotcomrow/orders/google"
  version = "> 1.0.0"
  project_name = "orderdata"
  gcp_org_id = "${var.gcp_org_id}"
  billing_account = "${var.billing_account}"
}

module "cart" {
  source  = "app.terraform.io/dotcomrow/cart/google"
  version = "> 1.0.0"
  project_name = "cartdata"
  gcp_org_id = "${var.gcp_org_id}"
  billing_account ="${var.billing_account}"
}

module "products" {
  source  = "app.terraform.io/dotcomrow/products/google"
  version = "> 1.0.0"
  project_name = "productdata"
  gcp_org_id = "${var.gcp_org_id}"
  billing_account = "${var.billing_account}"
}