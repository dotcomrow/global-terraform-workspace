# resource "google_service_account" "data-layer-bigquery" {
#   account_id   = "data-layer-bigquery"
#   display_name = "data-layer-bigquery"
# }

# resource "google_project_iam_binding" "data-layer-bigquery" {
#   project = var.project
#   role    = "roles/bigquery.dataEditor"
#   members = [
#     "serviceAccount:${google_service_account.data-layer-bigquery.email}"
#   ]
# }

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