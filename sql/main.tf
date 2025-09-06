# Configure Google Cloud provider for SQL resources
provider "google" {
  region = var.region
}

# Retrieve network configuration from Shared VPC state
# Provides network IDs and subnet configurations for SQL instances
data "terraform_remote_state" "net_svpc" {
  backend = "gcs"
  config = {
    bucket = var.net_svpc_backend_bucket
    prefix = var.net_svpc_backend_prefix
  }
}

# Retrieve service project IDs from remote state
# Contains data project ID for SQL deployment
data "terraform_remote_state" "svc_projects" {
  backend = "gcs"
  config = {
    bucket = var.svc_projects_backend_bucket
    prefix = var.svc_projects_backend_prefix
  }
}

# Retrieve IAM configuration from remote state
# Contains security roles and access policies
data "terraform_remote_state" "net_iam" {
  backend = "gcs"
  config = {
    bucket = var.net_iam_backend_bucket
    prefix = var.net_iam_backend_prefix
  }
}

# Define local variables for SQL instance configuration
# Consolidates project IDs, network details, and naming conventions
locals {
  data_project_id   = data.terraform_remote_state.svc_projects.outputs.data_project_id
  host_project_id   = data.terraform_remote_state.net_svpc.outputs.host_project_id
  data_network_id   = data.terraform_remote_state.net_svpc.outputs.data_network_id
  data_network_name = data.terraform_remote_state.net_svpc.outputs.data_network_name
  data_subnet_id    = data.terraform_remote_state.net_svpc.outputs.data_subnet_id

  sql_instance_name = var.sql_config.instance_name_suffix != "" ? "${var.sql_config.instance_name_suffix}" : "cloud-sql"

  common_labels = merge(var.labels, {
    environment     = "production"
    project         = "data-project"
    managed_by      = "terraform"
    deployment_date = formatdate("YYYY-MM-DD", timestamp())
    component       = "cloudsql"
  })
}

# Enable Cloud SQL Admin API for instance management
# Required for creating and managing Cloud SQL instances
resource "google_project_service" "cloudsql_admin_api" {
  project = local.data_project_id
  service = "sqladmin.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}

# Enable Cloud SQL component API
# Required for SQL instance operations
resource "google_project_service" "cloudsql_api" {
  project = local.data_project_id
  service = "sql-component.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}

# Enable Compute Engine API for network connectivity
# Required for private IP configuration
resource "google_project_service" "compute_api" {
  project = local.data_project_id
  service = "compute.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}

# Enable Service Networking API for private service connection
# Enables private IP connectivity to Cloud SQL
resource "google_project_service" "servicenetworking_api" {
  project = local.data_project_id
  service = "servicenetworking.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}

# Create Cloud SQL instances for different workloads
# Each instance is configured with high availability and security features
module "fintech_cloudsql_instances" {
  for_each = var.sql_instances_config
  source   = "git::https://github.com/cloudon-one/gcp-terraform-modules.git//terraform-google-cloudsql?ref=main"

  project_id       = local.data_project_id
  instance_name    = each.key == "analytics" ? local.sql_instance_name : "${local.sql_instance_name}-${each.key}"
  database_version = each.value.database_version
  region           = var.region

  machine_type          = each.value.machine_type
  disk_type             = each.value.disk_type
  disk_size             = each.value.disk_size
  disk_autoresize       = each.value.disk_autoresize
  disk_autoresize_limit = each.value.disk_autoresize_limit
  availability_type     = each.value.availability_type
  primary_zone          = each.value.primary_zone
  deletion_protection   = each.value.deletion_protection

  # Configure private IP connectivity for secure database access
  # Disables public IP and enforces SSL connections
  ip_configuration = {
    ipv4_enabled                                  = false
    private_network                               = local.data_network_id
    require_ssl                                   = true
    allocated_ip_range                            = "private-sql"
    enable_private_path_for_google_cloud_services = true
    authorized_networks                           = []
  }

  # Configure automated backups with point-in-time recovery
  # Ensures data durability and disaster recovery capability
  backup_configuration = {
    enabled                        = true
    start_time                     = "00:00"
    point_in_time_recovery_enabled = true
    transaction_log_retention_days = 14
    retained_backups               = 30
    location                       = "eu"
  }

  # Schedule maintenance window during low-traffic periods
  # Friday nights to minimize business impact
  maintenance_window = {
    day          = 5  # Friday
    hour         = 22 # 10 PM
    update_track = "stable"
  }

  database_flags = each.value.database_flags

  # Enable Query Insights for performance monitoring
  # Tracks slow queries and application patterns
  insights_config = {
    query_insights_enabled  = true
    query_string_length     = 10000
    record_application_tags = true
    record_client_address   = true
  }

  databases                    = each.value.databases
  users                        = each.value.users
  read_replicas                = each.value.read_replicas
  edition                      = "ENTERPRISE_PLUS"
  data_cache_enabled           = true
  enable_google_ml_integration = true
  retain_backups_on_delete     = true

  user_labels = {
    cost_center = "devops"
    environment = "production"
    owner       = "devops"
    team        = "devops"
  }

  depends_on = [
    google_project_service.cloudsql_admin_api,
    google_project_service.cloudsql_api,
    google_project_service.compute_api,
    google_project_service.servicenetworking_api
  ]
}

# Configure firewall rule for GKE to Cloud SQL connectivity
# Allows database access from Kubernetes workloads
resource "google_compute_firewall" "cloudsql_access_from_gke" {
  name    = "allow-cloudsql-access-from-gke"
  network = local.data_network_name
  project = local.host_project_id

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_ranges      = ["10.160.0.0/16"]
  destination_ranges = ["10.161.1.0/24", "10.161.2.0/24"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }

  description = "Allow Cloud SQL access from GKE cluster"
}

# Configure firewall rule for data VPC internal access
# Enables data processing workloads to access databases
resource "google_compute_firewall" "cloudsql_access_from_data" {
  name    = "allow-cloudsql-access-from-data"
  network = local.data_network_name
  project = local.host_project_id

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_ranges      = ["10.161.0.0/16"]
  destination_ranges = ["10.161.1.0/24", "10.161.2.0/24"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }

  description = "Allow Cloud SQL access from data VPC"
}

# Configure firewall rule for IAP tunnel access
# Enables secure administrative access through Identity-Aware Proxy
resource "google_compute_firewall" "cloudsql_access_from_iap" {
  name    = "allow-cloudsql-access-from-iap"
  network = local.data_network_name
  project = local.host_project_id

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_ranges      = ["35.235.240.0/20"]
  destination_ranges = ["10.161.1.0/24", "10.161.2.0/24"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }

  description = "Allow Cloud SQL access from IAP"
} 