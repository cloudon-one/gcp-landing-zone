data "terraform_remote_state" "svc_projects" {
  backend = "gcs"
  config = {
    bucket = "tfstate-bucket"
    prefix = "svc-projects"
  }
}

locals {
  gke_project_id = data.terraform_remote_state.svc_projects.outputs.gke_project_id
}

resource "google_project_iam_binding" "container_viewers_devops" {
  project = local.gke_project_id
  role    = "roles/container.viewer"

  members = [
    "group:devops@example.com",
  ]
}

resource "google_project_iam_binding" "container_developers" {
  project = local.gke_project_id
  role    = "roles/container.developer"

  members = [
    "group:backend@example.com",
    "group:frontend@example.com",
    "group:mobile@example.com",
  ]
}

resource "google_project_iam_binding" "monitoring_viewers" {
  project = local.gke_project_id
  role    = "roles/monitoring.viewer"

  members = [
    "group:qa@example.com",
    "group:devops@example.com"
  ]
}

resource "google_project_iam_binding" "logging_viewers" {
  project = local.gke_project_id
  role    = "roles/logging.viewer"

  members = [
    "group:devops@example.com",
    "group:qa@example.com"
  ]
}