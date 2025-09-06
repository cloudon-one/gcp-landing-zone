# Deploy VPC Service Controls for enhanced security perimeter
# Restricts data exfiltration and enforces access boundaries
module "vpc_sc" {
  source = "git::https://github.com/cloudon-one/gcp-terraform-modules.git//terraform-google-vpc-sc?ref=main"

  organization_id                        = var.organization_id
  host_project_id                        = var.host_project_id
  gke_project_id                         = var.gke_project_id
  data_project_id                        = var.data_project_id
  devops_team_members                    = var.devops_team_members
  backend_team_members                   = var.backend_team_members
  frontend_team_members                  = var.frontend_team_members
  mobile_team_members                    = var.mobile_team_members
  service_accounts                       = var.service_accounts
  gke_workload_identity_service_accounts = var.gke_workload_identity_service_accounts
  iap_tunnel_users                       = var.iap_tunnel_users
  restricted_services                    = var.restricted_services
  bridge_services                        = var.bridge_services
  vpc_restricted_services                = var.vpc_restricted_services
}