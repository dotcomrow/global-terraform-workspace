provider "google" {
  project = var.project
  region  = var.region
  credentials = file(var.credentials_file) 
}

module "gcloud" {
  source  = "terraform-google-modules/gcloud/google"
  version = "3.2.1"
}