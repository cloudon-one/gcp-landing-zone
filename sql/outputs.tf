output "cloudsql_instances" {
  description = "Map of Cloud SQL instances"
  value = {
    for name, instance in module.fintech_cloudsql_instances : name => {
      instance_name                 = instance.instance_name
      instance_id                   = instance.instance_id
      connection_name               = instance.connection_name
      private_ip_address            = instance.private_ip_address
      public_ip_address             = instance.public_ip_address
      self_link                     = instance.self_link
      service_account_email_address = instance.service_account_email_address
      databases                     = instance.databases
      users                         = instance.users
      read_replicas                 = instance.read_replicas
      instance_settings             = instance.instance_settings
    }
  }
}

output "cloudsql_instance_names" {
  description = "List of Cloud SQL instance names"
  value       = [for name, instance in module.fintech_cloudsql_instances : instance.instance_name]
}

output "cloudsql_connection_names" {
  description = "List of Cloud SQL connection names"
  value       = [for name, instance in module.fintech_cloudsql_instances : instance.connection_name]
}

output "cloudsql_private_ips" {
  description = "Map of Cloud SQL instance names to private IP addresses"
  value       = { for name, instance in module.fintech_cloudsql_instances : name => instance.private_ip_address }
}

output "cloudsql_public_ips" {
  description = "Map of Cloud SQL instance names to public IP addresses"
  value       = { for name, instance in module.fintech_cloudsql_instances : name => instance.public_ip_address }
}

output "cloudsql_databases" {
  description = "Map of all databases across all instances"
  value = merge([
    for name, instance in module.fintech_cloudsql_instances : {
      for db_name, db in instance.databases : "${name}-${db_name}" => {
        instance_name = name
        database_name = db_name
        database_info = db
      }
    }
  ]...)
}

output "cloudsql_users" {
  description = "Map of all users across all instances"
  value = merge([
    for name, instance in module.fintech_cloudsql_instances : {
      for user_name, user in instance.users : "${name}-${user_name}" => {
        instance_name = name
        user_name     = user_name
        user_info     = user
      }
    }
  ]...)
}

output "cloudsql_read_replicas" {
  description = "Map of all read replicas across all instances"
  value = merge([
    for name, instance in module.fintech_cloudsql_instances : {
      for replica_name, replica in instance.read_replicas : "${name}-${replica_name}" => {
        instance_name = name
        replica_name  = replica_name
        replica_info  = replica
      }
    }
  ]...)
}

output "cloudsql_admin_service_account" {
  description = "Cloud SQL admin service account information"
  value = var.sql_config.create_service_account ? {
    email = data.terraform_remote_state.net_iam.outputs.cloudsql_admin_service_account_email
    name  = data.terraform_remote_state.net_iam.outputs.cloudsql_admin_service_account_name
    id    = data.terraform_remote_state.net_iam.outputs.cloudsql_admin_service_account_id
  } : null
}

output "cloudsql_firewall_rules" {
  description = "Cloud SQL firewall rules information"
  value = {
    gke_access = {
      name      = google_compute_firewall.cloudsql_access_from_gke.name
      id        = google_compute_firewall.cloudsql_access_from_gke.id
      self_link = google_compute_firewall.cloudsql_access_from_gke.self_link
    }
    data_access = {
      name      = google_compute_firewall.cloudsql_access_from_data.name
      id        = google_compute_firewall.cloudsql_access_from_data.id
      self_link = google_compute_firewall.cloudsql_access_from_data.self_link
    }
    iap_access = {
      name      = google_compute_firewall.cloudsql_access_from_iap.name
      id        = google_compute_firewall.cloudsql_access_from_iap.id
      self_link = google_compute_firewall.cloudsql_access_from_iap.self_link
    }
  }
}

output "enabled_apis" {
  description = "APIs enabled for Cloud SQL service"
  value = {
    cloudsql_admin_api    = google_project_service.cloudsql_admin_api.service
    cloudsql_api          = google_project_service.cloudsql_api.service
    compute_api           = google_project_service.compute_api.service
    servicenetworking_api = google_project_service.servicenetworking_api.service
  }
} 