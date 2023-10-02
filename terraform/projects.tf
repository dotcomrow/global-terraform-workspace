resource "google_project" "products" {
  name       = "products"
  project_id = "suncoast-systems-products-domain"
  org_id     = "${var.gcp_org_id}"
}

resource "google_project_service" "products" {
  project = google_project.products.project_id
  service = "iam.googleapis.com"
}

resource "google_project_service" "products2" {
  project = google_project.products.project_id
  service = "cloudresourcemanager.googleapis.com"
}

resource "google_project_service" "products3" {
  project = google_project.products.project_id
  service = "cloudbilling.googleapis.com"
}

