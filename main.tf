provider "google" {
  region  = "${var.region}"
}

variable "common_project_name" {
  description = "The name of project to store global bigquery service account"
  type = string
}

variable "region" {
  description = "The region to deploy resources"
  type        = string
}

variable "gcp_org_id" {
  description = "The GCP organization id"
  type        = string
}

variable "billing_account" {
  description = "The billing account id"
  type        = string
}

module "orders" {
  source  = "app.terraform.io/dotcomrow/orders/google"
  version = "> 1.0.0"
  project_name = "ordersdomn"
  gcp_org_id = "${var.gcp_org_id}"
  billing_account = "${var.billing_account}"
}

module "cart" {
  source  = "app.terraform.io/dotcomrow/cart/google"
  version = "> 1.0.0"
  project_name = "cartsdomn"
  gcp_org_id = "${var.gcp_org_id}"
  billing_account ="${var.billing_account}"
}

module "products" {
  source  = "app.terraform.io/dotcomrow/products/google"
  version = "> 1.0.0"
  project_name = "productsdomn"
  gcp_org_id = "${var.gcp_org_id}"
  billing_account = "${var.billing_account}"
}