output "network_policies" {
  description = "Network policies created"
  value = {
    default_deny = module.default_deny_policies
    backend      = module.backend_network_policies
    frontend     = module.frontend_network_policies
    api          = module.api_network_policies
    monitoring   = module.monitoring_network_policies
    database     = module.database_network_policies
  }
}

output "policy_count" {
  description = "Total number of network policies created"
  value = {
    default_deny = length(module.default_deny_policies)
    backend      = length(module.backend_network_policies)
    frontend     = length(module.frontend_network_policies)
    api          = length(module.api_network_policies)
    monitoring   = length(module.monitoring_network_policies)
    database     = length(module.database_network_policies)
  }
} 