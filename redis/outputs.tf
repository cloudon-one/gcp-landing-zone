output "redis_instances" {
  description = "Map of Redis instances"
  value = {
    for name, instance in module.fintech_redis_instances : name => {
      instance_name     = instance.instance_name
      instance_id       = instance.instance_id
      host              = instance.host
      port              = instance.port
      connection_string = instance.connection_string
      tier              = instance.tier
      memory_size_gb    = instance.memory_size_gb
      redis_version     = instance.redis_version
      auth_enabled      = instance.auth_enabled
      connect_mode      = instance.connect_mode
      replica_count     = instance.replica_count
    }
  }
}

output "main_redis_instance" {
  description = "Main Redis instance details"
  value = module.fintech_redis_instances["main"] != null ? {
    instance_name     = module.fintech_redis_instances["main"].instance_name
    instance_id       = module.fintech_redis_instances["main"].instance_id
    host              = module.fintech_redis_instances["main"].host
    port              = module.fintech_redis_instances["main"].port
    connection_string = module.fintech_redis_instances["main"].connection_string
    tier              = module.fintech_redis_instances["main"].tier
    memory_size_gb    = module.fintech_redis_instances["main"].memory_size_gb
    redis_version     = module.fintech_redis_instances["main"].redis_version
    auth_enabled      = module.fintech_redis_instances["main"].auth_enabled
    connect_mode      = module.fintech_redis_instances["main"].connect_mode
    replica_count     = module.fintech_redis_instances["main"].replica_count
  } : null
  sensitive = true
}

output "redis_auth_string" {
  description = "Redis AUTH string for the main instance (sensitive)"
  value       = module.fintech_redis_instances["main"] != null ? module.fintech_redis_instances["main"].auth_string : null
  sensitive   = true
}

output "redis_configs" {
  description = "Redis configuration parameters for all instances"
  value = {
    for name, instance in module.fintech_redis_instances : name => instance.redis_configs
  }
}

output "maintenance_policies" {
  description = "Maintenance policy information for all instances"
  value = {
    for name, instance in module.fintech_redis_instances : name => instance.maintenance_policy
  }
}

output "persistence_configs" {
  description = "Persistence configuration for all instances"
  value = {
    for name, instance in module.fintech_redis_instances : name => instance.persistence_config
  }
}

output "firewall_rules" {
  description = "Firewall rules created for Redis access"
  value = {
    gke_access = {
      name        = google_compute_firewall.redis_access_from_gke.name
      source      = "10.160.0.0/16"
      destination = "10.161.12.0/28"
      ports       = ["6379"]
    }
    data_access = {
      name        = google_compute_firewall.redis_access_from_data.name
      source      = "10.161.0.0/16"
      destination = "10.161.12.0/28"
      ports       = ["6379"]
    }
    iap_access = {
      name        = google_compute_firewall.redis_access_from_iap.name
      source      = "35.235.240.0/20"
      destination = "10.161.12.0/28"
      ports       = ["6379"]
    }
  }
} 