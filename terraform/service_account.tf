resource "google_service_account" "service_account" {
  account_id   = "${var.project_name}-cicd"
  project      = "${var.project_name}"
  display_name = "${var.project_name} GitHub Actions Service Account"
}

resource "google_project_iam_binding" "service_account_iam" {
  project = "${var.project_name}"
  role    = "roles/editor"
  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}

resource "google_service_account_key" "key" {
  service_account_id = google_service_account.service_account.name
}

resource "google_secret_manager_secret" "service_account" {
  secret_id = google_service_account.service_account.account_id

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
  project = var.project_name
}

resource "google_secret_manager_secret_version" "service_account_private_key" {
  secret = google_secret_manager_secret.service_account.id
  secret_data = base64decode(google_service_account_key.key.private_key)
}