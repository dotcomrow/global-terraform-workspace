provider "google" {
  region  = "${var.region}"
}

module "orders" {
  source  = "app.terraform.io/dotcomrow/orders/google"
  version = "> 1.0.0"
  project_name = "orders"
  project_id = "orders-${var.suffix}"
  gcp_org_id = "${var.gcp_org_id}"
  billing_account = "${var.billing_account}"
  region  = "${var.region}"
  bigquery_secret = "${var.bigquery_secret}"
  python_session_secret = "${var.python_session_secret}"
  audience = "${var.audience}"
}

module "carts" {
  source  = "app.terraform.io/dotcomrow/cart/google"
  version = "> 1.0.0"
  project_name = "carts"
  project_id = "carts-${var.suffix}"
  gcp_org_id = "${var.gcp_org_id}"
  billing_account ="${var.billing_account}"
  region  = "${var.region}"
  bigquery_secret = "${var.bigquery_secret}"
  python_session_secret = "${var.python_session_secret}"
  common_project_id = "${var.common_project_id}"
  audience = "${var.audience}"
}

module "products" {
  source  = "app.terraform.io/dotcomrow/products/google"
  version = "> 1.0.0"
  project_name = "products"
  project_id = "products-${var.suffix}"
  gcp_org_id = "${var.gcp_org_id}"
  billing_account = "${var.billing_account}"
  region  = "${var.region}"
  bigquery_secret = "${var.bigquery_secret}"
  python_session_secret = "${var.python_session_secret}"
  common_project_id = "${var.common_project_id}"
  audience = "${var.audience}"
}

module "configuration" {
  source  = "app.terraform.io/dotcomrow/configuration/google"
  version = "> 1.0.0"
  project_name = "configuration"
  project_id = "configuration-${var.suffix}"
  gcp_org_id = "${var.gcp_org_id}"
  billing_account = "${var.billing_account}"
  region  = "${var.region}"
  bigquery_secret = "${var.bigquery_secret}"
  python_session_secret = "${var.python_session_secret}"
  common_project_id = "${var.common_project_id}"
  audience = "${var.audience}"
  config_security_group = "${var.config_security_group}"
}