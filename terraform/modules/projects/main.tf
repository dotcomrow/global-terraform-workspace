resource "google_project" "project" {
  name       = "${var.project_name}"
  project_id = "${var.project_name}-dom"
  org_id     = "${var.gcp_org_id}"
}

resource "google_project_service" "project_service" {
  count = length(var.apis)

  resource_id     = var.object_list[count.index].id
  service = var.object_list[count.index].service
}