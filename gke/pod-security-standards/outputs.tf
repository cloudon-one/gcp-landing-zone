output "pod_security_standards_enabled" {
  description = "Whether Pod Security Standards are enabled"
  value       = var.pod_security_standards_config.mode != "DISABLED"
}

output "pod_security_standards_mode" {
  description = "The Pod Security Standards mode"
  value       = var.pod_security_standards_config.mode
}

output "pod_security_standards_version" {
  description = "The Pod Security Standards version"
  value       = var.pod_security_standards_config.version
}

output "namespaces_with_psa" {
  description = "Namespaces with Pod Security Standards applied"
  value = {
    kube_system   = kubernetes_labels.kube_system_psa.metadata[0].name
    default       = kubernetes_labels.default_psa.metadata[0].name
    monitoring    = kubernetes_labels.monitoring_psa.metadata[0].name
    ingress_nginx = kubernetes_namespace.ingress_nginx_psa.metadata[0].name
  }
} 