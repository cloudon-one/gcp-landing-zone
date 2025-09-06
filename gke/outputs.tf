output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = var.gke_config.enabled ? module.fintech_gke_cluster[0].cluster_name : null
}

output "cluster_id" {
  description = "The ID of the GKE cluster"
  value       = var.gke_config.enabled ? module.fintech_gke_cluster[0].cluster_id : null
}

output "cluster_location" {
  description = "The location of the GKE cluster"
  value       = var.gke_config.enabled ? var.region : null
}

output "cluster_endpoint" {
  description = "The IP address of the cluster master"
  value       = var.gke_config.enabled ? module.fintech_gke_cluster[0].cluster_endpoint : null
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The cluster CA certificate"
  value       = var.gke_config.enabled ? module.fintech_gke_cluster[0].cluster_ca_certificate : null
  sensitive   = true
}

output "service_account_email" {
  description = "The email of the service account created for the cluster"
  value       = var.gke_config.enabled ? module.fintech_gke_cluster[0].service_account_email : null
}

output "node_pools" {
  description = "List of node pools"
  value       = var.gke_config.enabled ? module.fintech_gke_cluster[0].node_pools : null
}

output "project_id" {
  description = "The project ID where the cluster is deployed"
  value       = local.gke_project_id
}

output "kubectl_config" {
  description = "kubectl configuration for accessing the cluster"
  value = var.gke_config.enabled ? {
    get_credentials_command = "gcloud container clusters get-credentials ${module.fintech_gke_cluster[0].cluster_name} --region ${var.region} --project ${local.gke_project_id}"
    cluster_name            = module.fintech_gke_cluster[0].cluster_name
    cluster_endpoint        = module.fintech_gke_cluster[0].cluster_endpoint
    context_name            = "gke_${local.gke_project_id}_${var.region}_${module.fintech_gke_cluster[0].cluster_name}"
  } : null
  sensitive = true
}

output "gke_cluster_summary" {
  description = "Summary of the GKE cluster configuration"
  value = var.gke_config.enabled ? {
    cluster_name                = module.fintech_gke_cluster[0].cluster_name
    cluster_location            = var.region
    master_ipv4_cidr_block      = var.gke_config.master_ipv4_cidr_block
    network_policy_enabled      = var.gke_config.enable_network_policy
    workload_identity_enabled   = var.gke_config.enable_workload_identity
    private_cluster_enabled     = var.gke_config.enable_private_nodes
    deletion_protection_enabled = var.gke_config.deletion_protection
  } : null
}

output "instance_group_urls" {
  description = "Map of node pool names to their instance group URLs"
  value       = module.fintech_gke_cluster[0].instance_group_urls
}

# Pod Security Standards outputs (deployed separately)
# output "pod_security_standards_enabled" {
#   description = "Whether Pod Security Standards are enabled"
#   value       = var.gke_config.enabled ? module.pod_security_standards[0].pod_security_standards_enabled : null
# }
#
# output "pod_security_standards_mode" {
#   description = "The Pod Security Standards mode"
#   value       = var.gke_config.enabled ? module.pod_security_standards[0].pod_security_standards_mode : null
# }
#
# output "pod_security_standards_version" {
#   description = "The Pod Security Standards version"
#   value       = var.gke_config.enabled ? module.pod_security_standards[0].pod_security_standards_version : null
# }
#
# output "namespaces_with_psa" {
#   description = "Namespaces with Pod Security Standards applied"
#   value       = var.gke_config.enabled ? module.pod_security_standards[0].namespaces_with_psa : null
# }

output "workload_service_accounts" {
  description = "Map of created workload identity service accounts"
  value = {
    for name, sa in google_service_account.workload_service_accounts : name => {
      email        = sa.email
      display_name = sa.display_name
      unique_id    = sa.unique_id
    }
  }
}

output "workload_identity_bindings" {
  description = "Workload Identity bindings for Kubernetes service accounts"
  value = {
    for name, config in var.gke_config.workload_identity_service_accounts : name => {
      gcp_service_account        = google_service_account.workload_service_accounts[name].email
      kubernetes_namespace       = config.kubernetes_namespace
      kubernetes_service_account = config.kubernetes_service_account
      gcp_roles                  = config.gcp_roles
    }
  }
}