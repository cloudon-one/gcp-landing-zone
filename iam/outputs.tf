output "gke_workload_identity_service_accounts" {
  description = "GKE workload identity service account emails"
  value       = module.iam.gke_workload_identity_service_accounts
}

output "cloudsql_admin_service_account_email" {
  description = "Cloud SQL admin service account email"
  value       = module.iam.cloudsql_admin_service_account_email
}

output "cloudsql_admin_service_account_name" {
  description = "Cloud SQL admin service account name"
  value       = module.iam.cloudsql_admin_service_account_name
}

output "cloudsql_admin_service_account_id" {
  description = "Cloud SQL admin service account ID"
  value       = module.iam.cloudsql_admin_service_account_id
}

output "gke_service_account_email" {
  description = "GKE service account email"
  value       = module.iam.gke_service_account_email
}

output "gke_service_account_name" {
  description = "GKE service account name"
  value       = module.iam.gke_service_account_name
}

output "gke_service_account_id" {
  description = "GKE service account ID"
  value       = module.iam.gke_service_account_id
}

output "iap_tunnel_users" {
  description = "List of users with IAP Tunnel access"
  value       = module.iam.iap_tunnel_users
} 