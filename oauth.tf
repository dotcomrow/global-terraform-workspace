# resource "google_iap_brand" "project_brand" {
#   support_email     = "administrator@suncoast.systems"
#   application_title = "Cloud IAP protected Application"
#   project           = var.common_project_id
# }

# resource "google_iap_client" "project_client" {
#   display_name = "UI Client"
#   brand        =  google_iap_brand.project_brand.name
# }