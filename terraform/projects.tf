resource "google_project" "products" {
  name       = "products"
  project_id = "suncoast-systems-products"
  org_id     = "${var.gcp_org_id}"
}