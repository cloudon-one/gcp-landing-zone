output "resource_quotas" {
  description = "Resource quotas created"
  value = {
    default    = kubernetes_resource_quota.default_quota.metadata[0].name
    production = kubernetes_resource_quota.production_quota.metadata[0].name
    monitoring = kubernetes_resource_quota.monitoring_quota.metadata[0].name
  }
}

output "limit_ranges" {
  description = "Limit ranges created"
  value = {
    default    = kubernetes_limit_range.default_limits.metadata[0].name
    production = kubernetes_limit_range.production_limits.metadata[0].name
  }
}

output "horizontal_pod_autoscalers" {
  description = "Horizontal Pod Autoscalers created"
  value = {
    app = kubernetes_horizontal_pod_autoscaler_v2.app_hpa.metadata[0].name
    api = kubernetes_horizontal_pod_autoscaler_v2.api_hpa.metadata[0].name
  }
}

output "pod_disruption_budgets" {
  description = "Pod Disruption Budgets created"
  value = {
    app        = kubernetes_pod_disruption_budget_v1.app_pdb.metadata[0].name
    api        = kubernetes_pod_disruption_budget_v1.api_pdb.metadata[0].name
    monitoring = kubernetes_pod_disruption_budget_v1.monitoring_pdb.metadata[0].name
  }
}

output "priority_classes" {
  description = "Priority classes created"
  value = {
    high   = kubernetes_priority_class_v1.high_priority.metadata[0].name
    medium = kubernetes_priority_class_v1.medium_priority.metadata[0].name
    low    = kubernetes_priority_class_v1.low_priority.metadata[0].name
  }
}

output "load_testing_enabled" {
  description = "Whether load testing is enabled"
  value       = var.performance_config.load_testing_enabled
}

output "burst_scaling_enabled" {
  description = "Whether burst scaling is enabled"
  value       = var.performance_config.enable_burst_scaling
}

output "node_auto_provisioning_enabled" {
  description = "Whether node auto-provisioning is enabled"
  value       = var.performance_config.enable_node_auto_provisioning
} 