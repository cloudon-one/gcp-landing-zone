provider "google" {
  region = var.region
}

data "terraform_remote_state" "net_svpc" {
  backend = "gcs"
  config = {
    bucket = var.net_svpc_backend_bucket
    prefix = var.net_svpc_backend_prefix
  }
}

data "terraform_remote_state" "svc_projects" {
  backend = "gcs"
  config = {
    bucket = var.svc_projects_backend_bucket
    prefix = var.svc_projects_backend_prefix
  }
}

locals {
  gke_project_id  = data.terraform_remote_state.svc_projects.outputs.gke_project_id
  data_project_id = data.terraform_remote_state.svc_projects.outputs.data_project_id
  host_project_id = data.terraform_remote_state.net_svpc.outputs.host_project_id
}

module "iam" {
  source = "git::https://github.com/cloudon-one/gcp-terraform-modules.git//terraform-google-iam?ref=main"

  enable_gke_iam = var.enable_gke_iam
  enable_sql_iam = var.enable_sql_iam

  host_project_id = local.host_project_id
  gke_project_id  = local.gke_project_id
  data_project_id = local.data_project_id

  gke_workload_identity_service_accounts = var.gke_workload_identity_service_accounts
  gke_service_account_config             = var.gke_service_account_config

  enable_os_login_iam = var.enable_os_login_iam
  os_login_users      = var.os_login_users

  enable_bastion_iam               = var.enable_bastion_iam
  bastion_service_account_config   = var.bastion_service_account_config
  folder_id                        = "12345678901234567890" # Replace with actual folder ID
  existing_bastion_service_account = "bastion@host-project.iam.gserviceaccount.com"

  enable_iap_tunnel_iam = var.enable_iap_tunnel_iam
  iap_tunnel_users      = var.iap_tunnel_users
} 