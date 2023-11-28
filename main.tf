provider "google" {
  region  = "${var.region}"
}

provider "google-beta" {
  region  = "${var.region}"
}

module "mfe" {
  source  = "app.terraform.io/dotcomrow/mfe/cloudflare"
  version = "> 1.0.0"
  cloudflare_account_id = "${var.cloudflare_account_id}"
  cloudflare_zone_id = "${var.cloudflare_zone_id}"
}