provider "google" {
  region  = "${var.region}"
}

module "orderproject" {
  source  = "app.terraform.io/dotcomrow/orders/google"
  version = "> 1.0.0"
  project_name = "orderproject"
  gcp_org_id = "${var.gcp_org_id}"
  billing_account = "${var.billing_account}"
}

module "cartproject" {
  source  = "app.terraform.io/dotcomrow/cart/google"
  version = "> 1.0.0"
  project_name = "cartproject"
  gcp_org_id = "${var.gcp_org_id}"
  billing_account ="${var.billing_account}"
}

module "productproject" {
  source  = "app.terraform.io/dotcomrow/products/google"
  version = "> 1.0.0"
  project_name = "productproject"
  gcp_org_id = "${var.gcp_org_id}"
  billing_account = "${var.billing_account}"
}