provider "google" {
  region  = "${var.region}"
}

module "api_gateway" {
  source  = "app.terraform.io/dotcomrow/api_gateway/cloudflare"
  version = "> 1.0.0"
  cloudflare_account_id = "${var.cloudflare_account_id}"
  cloudflare_cache_max_age = "${var.cloudflare_cache_max_age}"
  cloudflare_cors_domains = ".*.${var.domain},localhost:8081"
  cloudflare_worker_hostname = "api.${var.domain}"
  cloudflare_worker_url_pattern = "api.${var.domain}/*"
  cloudflare_worker_zone_id = "${var.cloudflare_zone_id}"
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
  cloudflare_account_id = "${var.cloudflare_account_id}"
  cloudflare_worker_namespace_id = "${module.api_gateway.api_gateway_namespace_id}"
  domain = var.domain
}

module "mfe" {
  source  = "app.terraform.io/dotcomrow/mfe/cloudflare"
  version = "> 1.0.0"
  cloudflare_account_id = "${var.cloudflare_account_id}"
  cloudflare_zone_id = "${var.cloudflare_zone_id}"
}