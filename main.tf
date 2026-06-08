provider "google" {
  region      = var.region
  credentials = var.google_credentials_tunnel_key_json
}

provider "google-beta" {
  region      = var.region
  credentials = var.google_credentials_tunnel_key_json
}
