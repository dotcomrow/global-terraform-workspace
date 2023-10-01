resource "google_service_account" "dl-products" {
  account_id   = "dl-products"
  display_name = "dl-products"
}

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