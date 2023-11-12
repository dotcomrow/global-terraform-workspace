resource "google_artifact_registry_repository" "registry" {
  provider      = google-beta
  repository_id = var.registry_name
  location      = "us"
  project       =  var.common_project_id
  format        = "DOCKER"
  cleanup_policy_dry_run = false
  cleanup_policies {
    id     = "keep-minimum-versions"
    action = "KEEP"
    most_recent_versions {
      package_name_prefixes = ["svc-"]
      keep_count            = 2
    }
  }
}

resource "google_artifact_registry_repository_iam_member" "member" {
  project = google_artifact_registry_repository.registry.project
  location = google_artifact_registry_repository.registry.location
  repository = google_artifact_registry_repository.registry.name
  role = "roles/artifactregistry.admin"
  member = "serviceAccount:terraform-cloud-cicd@org-service-accounts-401323.iam.gserviceaccount.com"
}