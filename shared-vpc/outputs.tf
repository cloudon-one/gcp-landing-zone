# Regional deployment information
output "region" {
  description = "Region where resources are deployed"
  value       = local.region
}

# GKE VPC CIDR blocks for network planning and firewall rules
output "gke_vpc_cidr" {
  description = "CIDR block of the GKE VPC"
  value       = local.gke_vpc_cidr
}

output "gke_subnet_cidr" {
  description = "CIDR block of the GKE subnet"
  value       = local.gke_subnet_cidr
}

output "gke_pods_cidr" {
  description = "CIDR block of the GKE pods secondary range"
  value       = local.gke_pods_cidr
}

output "gke_services_cidr" {
  description = "CIDR block of the GKE services secondary range"
  value       = local.gke_services_cidr
}

output "gke_control_plane_cidr" {
  description = "CIDR block of the GKE control plane"
  value       = local.gke_control_plane_cidr
}

output "data_vpc_cidr" {
  description = "CIDR block of the Data VPC"
  value       = local.data_vpc_cidr
}

output "data_subnet_cidr" {
  description = "CIDR block of the Data subnet"
  value       = local.data_subnet_cidr
}

output "data_composer_pods_cidr" {
  description = "CIDR block of the Data Composer pods secondary range"
  value       = local.data_composer_pods_cidr
}

output "data_composer_services_cidr" {
  description = "CIDR block of the Data Composer services secondary range"
  value       = local.data_composer_services_cidr
}

# Project outputs for cross-module references
# Host project manages shared VPC resources
output "host_project_id" {
  description = "ID of the host project"
  value       = var.project_id
}

output "gke_project_id" {
  description = "ID of the GKE project (host project for IAP)"
  value       = var.project_id
}

# Network outputs for GKE cluster configuration
# These outputs are consumed by the svc-gke module
output "gke_network_id" {
  description = "ID of the GKE VPC network"
  value       = module.gke_vpc.vpc_id
}

output "gke_network_name" {
  description = "Name of the GKE VPC network"
  value       = var.gke_vpc_name
}

output "gke_subnet_id" {
  description = "ID of the GKE subnet"
  value       = module.gke_vpc.subnets["gke"].id
}

output "gke_subnet_name" {
  description = "Name of the GKE subnet"
  value       = var.gke_subnet.name
}

output "gke_pods_secondary_range_name" {
  description = "Name of the GKE pods secondary range"
  value       = "gke-pods"
}

output "gke_services_secondary_range_name" {
  description = "Name of the GKE services secondary range"
  value       = "gke-services"
}

output "data_network_id" {
  description = "ID of the Data VPC network"
  value       = module.data_vpc.vpc_id
}

output "data_network_name" {
  description = "Name of the Data VPC network"
  value       = var.data_vpc_name
}

output "data_subnet_id" {
  description = "ID of the Data subnet"
  value       = module.data_vpc.subnets["data"].id
}

output "data_subnet_name" {
  description = "Name of the Data subnet"
  value       = var.data_subnet.name
}

# GKE VPC detailed outputs for peering and routing
# Used for VPC peering and NAT configuration
output "gke_vpc_id" {
  description = "The ID of the GKE VPC"
  value       = module.gke_vpc.vpc_id
}

output "gke_vpc_self_link" {
  description = "The self-link of the GKE VPC"
  value       = module.gke_vpc.vpc_self_link
}

output "gke_router_name" {
  description = "The name of the GKE Cloud Router"
  value       = "gke-router"
}

output "gke_nat_name" {
  description = "The name of the GKE Cloud NAT"
  value       = "gke-nat"
}

output "data_vpc_id" {
  description = "The ID of the Data VPC"
  value       = module.data_vpc.vpc_id
}

output "data_vpc_self_link" {
  description = "The self-link of the Data VPC"
  value       = module.data_vpc.vpc_self_link
}

output "data_router_name" {
  description = "The name of the Data Cloud Router"
  value       = "data-router"
}

output "data_nat_name" {
  description = "The name of the Data Cloud NAT"
  value       = "data-nat"
}
