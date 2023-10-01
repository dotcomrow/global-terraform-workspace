resource "google_project" "my_project_12341234" {
  name       = "My Project"
  project_id = "jgfdgfd-7856786"
  org_id     = "${var.gcp_org_id}"
}