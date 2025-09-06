# Configure Google Cloud provider for Redis resources
provider "google" {
  region = var.region
}

# Retrieve network configuration from Shared VPC state
# Provides network IDs for Redis private connectivity
data "terraform_remote_state" "net_svpc" {
  backend = "gcs"
  config = {
    bucket = var.net_svpc_backend_bucket
    prefix = var.net_svpc_backend_prefix
  }
}

# Retrieve data project ID from service projects state
# Redis instances are deployed in the data project
data "terraform_remote_state" "svc_projects" {
  backend = "gcs"
  config = {
    bucket = var.svc_projects_backend_bucket
    prefix = var.svc_projects_backend_prefix
  }
}

# Retrieve IAM configuration from remote state
# Contains access policies and security groups
data "terraform_remote_state" "net_iam" {
  backend = "gcs"
  config = {
    bucket = var.net_iam_backend_bucket
    prefix = var.net_iam_backend_prefix
  }
}

# Define local variables for Redis configuration
# Consolidates project IDs, network details, and naming patterns
locals {
  data_project_id   = data.terraform_remote_state.svc_projects.outputs.data_project_id
  host_project_id   = data.terraform_remote_state.net_svpc.outputs.host_project_id
  data_network_id   = data.terraform_remote_state.net_svpc.outputs.data_network_id
  data_network_name = data.terraform_remote_state.net_svpc.outputs.data_network_name

  redis_instance_name = var.redis_config.instance_name_suffix != "" ? "${var.redis_config.instance_name_suffix}" : "redis"

  common_labels = merge(var.labels, {
    environment = "production"
    project     = "data-project"
    managed_by  = "terraform"
    component   = "redis-memorystore"
  })
}

# Enable Redis API for Memorystore management
# Required for creating and managing Redis instances
resource "google_project_service" "redis_api" {
  project = local.data_project_id
  service = "redis.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}

# Enable Service Networking API for private service connection
# Required for private IP connectivity to Redis
resource "google_project_service" "servicenetworking_api" {
  project = local.data_project_id
  service = "servicenetworking.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}

# Create Memorystore Redis instances for caching and session storage
# Configured with high availability and encryption
module "fintech_redis_instances" {
  for_each = var.redis_instances_config
  source   = "git::https://github.com/cloudon-one/gcp-terraform-modules.git//terraform-google-memorystore?ref=main"

  project_id    = local.data_project_id
  instance_name = each.key == "main" ? local.redis_instance_name : "${local.redis_instance_name}-${each.key}"
  region        = var.region

  tier           = each.value.tier
  memory_size_gb = each.value.memory_size_gb
  redis_version  = each.value.redis_version

  authorized_network = local.data_network_id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"
  reserved_ip_range  = "private-redis"

  # Enable authentication and encryption for security
  # Protects data in transit between clients and Redis
  auth_enabled            = true
  transit_encryption_mode = "SERVER_AUTHENTICATION"

  # Schedule maintenance during low-traffic periods
  # Sunday early morning to minimize impact
  maintenance_window = {
    day    = "SUNDAY" # Sunday
    hour   = 2        # 2 AM
    minute = 0
  }

  # Configure data persistence with RDB snapshots
  # Ensures data durability with regular backups
  persistence_config = {
    persistence_mode    = "RDB"
    rdb_snapshot_period = "TWELVE_HOURS"
  }

  redis_configs = each.value.redis_configs

  # Configure read replicas for high availability and read scaling
  # Distributes read load across multiple instances
  replica_count      = each.value.replica_count
  read_replicas_mode = "READ_REPLICAS_ENABLED"

  user_labels = merge(local.common_labels, {
    cost_center = "devops"
    owner       = "devops"
    team        = "devops"
  })

  depends_on = [
    google_project_service.redis_api,
    google_project_service.servicenetworking_api
  ]
}

# Configure firewall rule for GKE to Redis connectivity
# Allows caching and session storage from Kubernetes workloads
resource "google_compute_firewall" "redis_access_from_gke" {
  name    = "allow-redis-access-from-gke"
  network = local.data_network_name
  project = local.host_project_id

  allow {
    protocol = "tcp"
    ports    = ["6379"]
  }

  source_ranges      = ["10.160.0.0/16"]
  destination_ranges = ["10.161.12.0/28"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }

  description = "Allow Redis access from GKE cluster"
}

# Configure firewall rule for data VPC internal access
# Enables data processing workloads to use Redis caching
resource "google_compute_firewall" "redis_access_from_data" {
  name    = "allow-redis-access-from-data"
  network = local.data_network_name
  project = local.host_project_id

  allow {
    protocol = "tcp"
    ports    = ["6379"]
  }

  source_ranges      = ["10.161.0.0/16"]
  destination_ranges = ["10.161.12.0/28"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }

  description = "Allow Redis access from data VPC"
}

# Configure firewall rule for IAP tunnel access
# Enables secure administrative access for debugging
resource "google_compute_firewall" "redis_access_from_iap" {
  name    = "allow-redis-access-from-iap"
  network = local.data_network_name
  project = local.host_project_id

  allow {
    protocol = "tcp"
    ports    = ["6379"]
  }

  source_ranges      = ["35.235.240.0/20"]
  destination_ranges = ["10.161.12.0/28"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }

  description = "Allow Redis access from IAP tunnel"
} 