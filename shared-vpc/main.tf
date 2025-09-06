# Retrieve service project information from remote state
# This allows the network module to access project IDs and service accounts
data "terraform_remote_state" "service_projects" {
  backend = "gcs"
  config = {
    bucket = var.backend_bucket
    prefix = var.svc_projects_backend_prefix
  }
}
# Define local variables for service project configurations
locals {
  # Filter and extract GKE service projects from remote state
  gke_service_projects = {
    for k, v in data.terraform_remote_state.service_projects.outputs.service_projects : k => v.project_id
    if v.type == "gke"
  }

  # Filter and extract data service projects from remote state
  data_service_projects = {
    for k, v in data.terraform_remote_state.service_projects.outputs.service_projects : k => v.project_id
    if v.type == "data"
  }

  # Configure IAM bindings for GKE subnets
  # Automatically includes GKE project service accounts alongside manually specified members
  gke_subnet_iam_bindings = {
    for subnet_name, subnet_config in var.gke_subnet_iam_bindings : subnet_name => {
      subnetwork = subnet_config.subnetwork
      region     = subnet_config.region
      members = concat(
        subnet_config.members,
        [
          for project_key, project in data.terraform_remote_state.service_projects.outputs.service_projects :
          "serviceAccount:${project.default_service_account}"
          if project.type == "gke"
        ]
      )
    }
  }

  # Configure IAM bindings for data subnets
  # Automatically includes data project service accounts alongside manually specified members
  data_subnet_iam_bindings = {
    for subnet_name, subnet_config in var.data_subnet_iam_bindings : subnet_name => {
      subnetwork = subnet_config.subnetwork
      region     = subnet_config.region
      members = concat(
        subnet_config.members,
        [
          for project_key, project in data.terraform_remote_state.service_projects.outputs.service_projects :
          "serviceAccount:${project.default_service_account}"
          if project.type == "data"
        ]
      )
    }
  }
}

# Create Shared VPC for GKE workloads
# This VPC hosts the GKE cluster and related resources
module "gke_vpc" {
  source = "git::https://github.com/cloudon-one/gcp-terraform-modules.git//terraform-google-svpc?ref=main"

  project_id = var.project_id
  vpc_name   = var.gke_vpc_name

  subnets = {
    gke           = merge(var.gke_subnet, { region = var.region })
    proxy         = merge(var.gke_proxy_subnet, { region = var.region })
    control-plane = merge(var.gke_control_plane_subnet, { region = var.region })
  }

  cloud_nat_config    = var.gke_cloud_nat_config
  firewall_rules      = var.gke_firewall_rules
  vpc_peering_config  = var.gke_vpc_peering_config
  enable_shared_vpc   = true
  service_projects    = local.gke_service_projects
  subnet_iam_bindings = local.gke_subnet_iam_bindings
  dns_config          = var.dns_config
  dns_records         = var.dns_records
  zone_name           = var.dns_zone_name
  dns_name            = var.dns_domain_name
  gke_vpc_self_link   = "projects/${var.project_id}/global/networks/${var.gke_vpc_name}"
  data_vpc_self_link  = "projects/${var.project_id}/global/networks/${var.data_vpc_name}"
  labels              = var.labels
}

# Create Shared VPC for data services
# This VPC hosts databases, storage, and data processing resources
module "data_vpc" {
  source     = "git::https://github.com/cloudon-one/gcp-terraform-modules.git//terraform-google-svpc?ref=main"
  project_id = var.project_id
  vpc_name   = var.data_vpc_name
  subnets = {
    data  = merge(var.data_subnet, { region = var.region })
    proxy = merge(var.data_proxy_subnet, { region = var.region })
  }

  cloud_nat_config              = var.data_cloud_nat_config
  firewall_rules                = var.data_firewall_rules
  vpc_peering_config            = var.data_vpc_peering_config
  enable_shared_vpc             = true
  service_projects              = local.data_service_projects
  subnet_iam_bindings           = local.data_subnet_iam_bindings
  private_service_access_ranges = var.data_private_service_access_ranges
  dns_config                    = var.dns_config
  dns_records                   = var.dns_records
  zone_name                     = var.dns_zone_name
  dns_name                      = var.dns_domain_name
  gke_vpc_self_link             = "projects/${var.project_id}/global/networks/${var.gke_vpc_name}"
  data_vpc_self_link            = "projects/${var.project_id}/global/networks/${var.data_vpc_name}"
  labels                        = var.labels
}

 