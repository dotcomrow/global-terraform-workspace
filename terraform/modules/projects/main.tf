resource "google_project" "project" {
  name       = "${var.project_name}"
  project_id = "${var.project_name}-dom"
  org_id     = "${var.gcp_org_id}"
}

resource "google_project_service" "project_service" {
  count = length(var.apis)

  project = google_project.project.project_id
  service = var.apis[count.index]
}

resource "google_service_account" "service_account" {
  account_id   = "${var.project_name}-cicd"
  display_name = "${var.project_name} GitHub Actions Service Account"
}

resource "google_project_iam_binding" "service_account_iam" {
  project = "${var.project_name}-dom"
  role    = "roles/editor"
  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}
