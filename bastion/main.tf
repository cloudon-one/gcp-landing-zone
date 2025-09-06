# Configure Google Cloud provider for bastion host deployment
provider "google" {
  region = var.region
}

# Retrieve network configuration from Shared VPC state
# Contains VPC names and subnet configurations for bastion placement
data "terraform_remote_state" "net_svpc" {
  backend = "gcs"
  config = {
    bucket = var.net_svpc_backend_bucket
    prefix = var.net_svpc_backend_prefix
  }
}

# Retrieve service project information from remote state
# Used for cross-project access configuration
data "terraform_remote_state" "svc_projects" {
  backend = "gcs"
  config = {
    bucket = var.svc_projects_backend_bucket
    prefix = var.svc_projects_backend_prefix
  }
}

# Consolidates project IDs and network names from remote state
locals {
  host_project_id  = data.terraform_remote_state.net_svpc.outputs.host_project_id
  gke_vpc_name     = data.terraform_remote_state.net_svpc.outputs.gke_network_name
  data_vpc_name    = data.terraform_remote_state.net_svpc.outputs.data_network_name
  gke_subnet_name  = "gke-subnet"
  data_subnet_name = "data-subnet"
  project_id       = local.host_project_id
}


# Deploy bastion host for secure administrative access
module "bastion" {
  source = "git::https://github.com/cloudon-one/gcp-terraform-modules.git//terraform-google-bastion?ref=main"

  project_id = local.project_id
  region     = var.region
  zone       = var.zone

  vpc_name                      = local.gke_vpc_name
  subnet_name                   = local.gke_subnet_name
  name_prefix                   = var.name_prefix
  service_account_name          = var.service_account_name
  machine_type                  = var.machine_type
  boot_image                    = var.boot_image
  boot_disk_size_gb             = var.boot_disk_size_gb
  boot_disk_type                = var.boot_disk_type
  authorized_networks           = var.authorized_networks
  ssh_keys                      = var.ssh_keys
  enable_iap_tunnel             = var.enable_iap_tunnel
  iap_user                      = var.iap_user
  enable_nat                    = var.enable_nat
  router_name                   = var.router_name
  deletion_protection           = var.deletion_protection
  enable_os_login               = var.enable_os_login
  os_login_users                = var.os_login_users
  sa_impersonators              = var.sa_impersonators
  enable_https_proxy            = var.enable_https_proxy
  proxy_port                    = var.proxy_port
  proxy_source_ranges           = var.proxy_source_ranges
  additional_network_interfaces = var.additional_network_interfaces
}