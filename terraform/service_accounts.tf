resource "google_service_account" "dl-products" {
  account_id   = "dl-products"
  display_name = "dl-products"
}

resource "null_resource" "enable_service_usage_api" {
  provisioner "local-exec" {
    command = "gcloud services enable serviceusage.googleapis.com cloudresourcemanager.googleapis.com --project suncoast-systems-products"
  }

  depends_on = [google_project.project]
}

# Wait for the new configuration to propagate
# (might be redundant)
resource "time_sleep" "wait_project_init" {
  create_duration = "60s"

  depends_on = [null_resource.enable_service_usage_api]
}

# resource "google_project_service" "dl-products" {
#   project = "suncoast-systems-products"
#   service = "iam.googleapis.com"
# }

resource "google_project_iam_binding" "dl-products" {
  project = "suncoast-systems-products"
  role    = "roles/owner"
  members = [
    "serviceAccount:${google_service_account.dl-products.email}"
  ]
}

# resource "google_service_account" "ol-layer" {
#   account_id   = "ol-layer"
#   display_name = "dol-layer"
# }

# resource "google_project_iam_binding" "ol-layer" {
#   project = var.project
#   role    = "roles/run.invoker"
#   members = [
#     "serviceAccount:${google_service_account.ol-layer.email}"
#   ]
# }