output "bastion_instance_name" {
  description = "The name of the bastion host instance"
  value       = module.bastion.bastion_instance_name
}

output "bastion_instance_id" {
  description = "The ID of the bastion host instance"
  value       = module.bastion.bastion_instance_id
}

output "bastion_external_ip" {
  description = "The external IP address of the bastion host"
  value       = module.bastion.bastion_external_ip
}

output "bastion_internal_ip" {
  description = "The internal IP address of the bastion host"
  value       = module.bastion.bastion_internal_ip
}

output "bastion_service_account_email" {
  description = "The email of the bastion host service account"
  value       = module.bastion.bastion_service_account_email
}

output "bastion_zone" {
  description = "The zone where the bastion host is deployed"
  value       = module.bastion.bastion_zone
}

output "bastion_ssh_command" {
  description = "SSH command to connect to the bastion host"
  value       = module.bastion.bastion_ssh_command
}

output "bastion_iap_command" {
  description = "IAP tunnel command to connect to the bastion host"
  value       = module.bastion.bastion_iap_command
}

output "bastion_router_name" {
  description = "The name of the Cloud Router created for the bastion host"
  value       = module.bastion.bastion_router_name
}

output "bastion_nat_name" {
  description = "The name of the Cloud NAT created for the bastion host"
  value       = module.bastion.bastion_nat_name
}

# Connection information
output "connection_info" {
  description = "Connection information for the bastion host"
  value = {
    instance_name = module.bastion.bastion_instance_name
    external_ip   = module.bastion.bastion_external_ip
    internal_ip   = module.bastion.bastion_internal_ip
    zone          = module.bastion.bastion_zone
    project_id    = local.project_id
    ssh_command   = module.bastion.bastion_ssh_command
    iap_command   = module.bastion.bastion_iap_command
    router_name   = module.bastion.bastion_router_name
    nat_name      = module.bastion.bastion_nat_name
  }
} 