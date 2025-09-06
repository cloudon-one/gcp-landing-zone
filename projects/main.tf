# Generate random suffix for host project ID
# Ensures globally unique project identifier
resource "random_string" "host_suffix" {
  length  = 4
  special = false
  upper   = false
}

# Generate random suffix for GKE service project
# Creates unique identifier for Kubernetes workload project
resource "random_string" "gke_suffix" {
  length  = 4
  special = false
  upper   = false
}

# Generate random suffix for data service project
# Creates unique identifier for data and storage project
resource "random_string" "data_suffix" {
  length  = 4
  special = false
  upper   = false
}

# Generate random suffixes for additional service projects
# Excludes GKE and data projects which have dedicated suffixes
resource "random_string" "service_project_suffixes" {
  for_each = { for k, v in var.service_projects : k => v if !contains(["gke", "data"], k) }

  length  = 4
  special = false
  upper   = false
}

# Create GCP projects for multi-project architecture
# Implements project isolation for security and resource management
module "service_projects" {
  source = "git::https://github.com/cloudon-one/gcp-terraform-modules.git//terraform-google-svc-projects?ref=main"

  billing_account_id               = var.billing_account_id
  folder_id                        = var.folder_id
  labels                           = var.labels
  disable_default_network_creation = var.disable_default_network_creation

  # Configure host project for Shared VPC
  # This project contains network resources shared by service projects
  host_project = {
    name   = var.host_project_name
    suffix = random_string.host_suffix.result
    apis   = var.host_project_apis
  }

  # Configure service projects attached to Shared VPC
  # Each project serves a specific purpose (GKE, data, etc.)
  service_projects = {
    for key, project in var.service_projects : key => {
      name = project.name
      suffix = key == "gke" ? random_string.gke_suffix.result : (
        key == "data" ? random_string.data_suffix.result :
        random_string.service_project_suffixes[key].result
      )
      type = project.type
      apis = project.apis
    }
  }
}