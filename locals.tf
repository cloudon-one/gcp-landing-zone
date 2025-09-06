# Centralized locals for consistent naming and tagging across all resources
# This ensures standardized resource naming and comprehensive labeling

locals {
  # Organization and project identifiers
  organization_name = "fintech"
  project_suffix    = "prod"
  environment       = "production"
  deployment_id     = formatdate("YYYY-MM-DD", timestamp())

  # Standardized naming conventions
  naming_convention = {
    separator = "-"
    format    = "${local.organization_name}-${local.project_suffix}"
  }

  # Resource name generators
  resource_names = {
    gke_cluster     = "${local.naming_convention.format}-gke"
    gke_vpc         = "${local.naming_convention.format}-gke-vpc"
    data_vpc        = "${local.naming_convention.format}-data-vpc"
    host_project    = "${local.naming_convention.format}-host"
    gke_project     = "${local.naming_convention.format}-gke"
    data_project    = "${local.naming_convention.format}-data"
    kms_keyring     = "${local.naming_convention.format}-kms"
    nat_gateway     = "${local.naming_convention.format}-nat"
    cloud_router    = "${local.naming_convention.format}-router"
    service_account = "${local.naming_convention.format}-sa"
  }

  # Standardized labels applied to all resources
  common_labels = {
    # Infrastructure metadata
    organization    = local.organization_name
    environment     = local.environment
    project_type    = "fintech-infrastructure"
    deployment_date = local.deployment_id
    managed_by      = "terraform"

    # Cost management and tracking
    cost_center     = "infrastructure"
    billing_code    = "infra-${local.environment}"
    owner_team      = "devops"
    budget_category = "compute"

    # Security and compliance
    security_level      = "high"
    data_classification = "confidential"
    compliance_scope    = "pci-dss"
    backup_required     = "true"
    monitoring_required = "true"

    # Operational metadata  
    terraform_workspace = terraform.workspace
    terraform_version   = "~> 1.0"
    provisioning_tool   = "terraform"

    # Business context
    business_unit      = "technology"
    application_tier   = "infrastructure"
    service_level      = "critical"
    maintenance_window = "weekend"
  }

  # Environment-specific configurations
  environment_config = {
    production = {
      deletion_protection = true
      backup_retention    = 2555 # 7 years in days
      log_retention       = 2555 # 7 years in days
      monitoring_level    = "enhanced"
      security_mode       = "strict"
    }
    staging = {
      deletion_protection = false
      backup_retention    = 90
      log_retention       = 365
      monitoring_level    = "standard"
      security_mode       = "standard"
    }
    development = {
      deletion_protection = false
      backup_retention    = 30
      log_retention       = 90
      monitoring_level    = "basic"
      security_mode       = "permissive"
    }
  }

  # Current environment configuration
  current_env_config = local.environment_config[local.environment]

  # Network CIDR allocations with clear documentation
  network_cidrs = {
    # GKE VPC network ranges
    gke_vpc = {
      primary           = "10.60.0.0/16"   # Main GKE network
      gke_nodes         = "10.60.0.0/20"   # Node subnets
      gke_pods          = "10.60.128.0/17" # Pod IP ranges  
      gke_services      = "10.60.224.0/20" # Service IP ranges
      gke_proxy         = "10.60.16.0/24"  # Proxy-only subnet
      gke_control_plane = "172.16.0.0/28"  # Private control plane
    }

    # Data VPC network ranges
    data_vpc = {
      primary          = "10.61.0.0/16"   # Main data network
      data_services    = "10.61.0.0/20"   # Data service subnets
      data_proxy       = "10.61.16.0/24"  # Proxy-only subnet
      private_services = "10.61.240.0/20" # Private service access
    }
  }

  # Security configuration templates
  security_templates = {
    high_security = {
      enable_shielded_nodes       = true
      enable_secure_boot          = true
      enable_integrity_monitoring = true
      enable_confidential_nodes   = true
      binary_authorization_mode   = "PROJECT_SINGLETON_POLICY_ENFORCE"
      pod_security_standard_mode  = "RESTRICTED"
      network_policy_enabled      = true
      private_endpoint_enabled    = true
      master_global_access        = false
      gcp_public_access           = false
    }

    standard_security = {
      enable_shielded_nodes       = true
      enable_secure_boot          = true
      enable_integrity_monitoring = true
      enable_confidential_nodes   = false
      binary_authorization_mode   = "DISABLED"
      pod_security_standard_mode  = "BASELINE"
      network_policy_enabled      = true
      private_endpoint_enabled    = false
      master_global_access        = false
      gcp_public_access           = false
    }
  }

  # Current security template
  security_config = local.security_templates["high_security"]
}