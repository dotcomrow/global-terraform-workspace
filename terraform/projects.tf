resource "google_project" "my_project_12341234" {
  name       = "My Project"
  project_id = "123134123412341234"
  org_id     = "${var.gcp_org_id}"
}