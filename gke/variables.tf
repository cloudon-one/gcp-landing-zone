variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.region))
    error_message = "Region must be a valid GCP region name."
  }
}
variable "net_svpc_backend_bucket" {
  description = "The GCS bucket for the network service state"
  type        = string
  default     = "tfstate-bucket"
}

variable "net_svpc_backend_prefix" {
  description = "The prefix for the network service state"
  type        = string
  default     = "net-svpc"
}

variable "svc_projects_backend_bucket" {
  description = "The GCS bucket for the service projects state"
  type        = string
  default     = "tfstate-bucket"
}

variable "svc_projects_backend_prefix" {
  description = "The prefix for the service projects state"
  type        = string
  default     = "svc-projects"
}

variable "net_iam_backend_bucket" {
  description = "The GCS bucket for the net-iam state"
  type        = string
  default     = "tfstate-bucket"
}

variable "net_iam_backend_prefix" {
  description = "The prefix for the net-iam state"
  type        = string
  default     = "net-iam"
}

variable "gke_config" {
  description = "GKE cluster configuration"
  type = object({
    enabled                = bool
    cluster_name_suffix    = string
    region                 = string
    network                = string
    subnetwork             = string
    master_ipv4_cidr_block = string
    master_authorized_networks = list(object({
      cidr_block   = string
      display_name = string
    }))
    enable_private_endpoint           = bool
    enable_private_nodes              = bool
    enable_workload_identity          = bool
    enable_network_policy             = bool
    enable_http_load_balancing        = bool
    enable_horizontal_pod_autoscaling = bool
    enable_vertical_pod_autoscaling   = bool
    enable_cloud_monitoring           = bool
    enable_cloud_logging              = bool
    enable_node_auto_provisioning     = bool
    enable_burst_scaling              = bool
    release_channel                   = string
    deletion_protection               = bool
    create_service_account            = bool
    workload_identity_service_accounts = map(object({
      display_name               = string
      description                = string
      kubernetes_namespace       = string
      kubernetes_service_account = string
      gcp_roles                  = list(string)
    }))
    timeouts = object({
      cluster_timeout   = string
      node_pool_timeout = string
    })
    maintenance_window = object({
      daily_window_start_time = string
      recurring_window = object({
        start_time = string
        end_time   = string
        recurrence = string
      })
    })
    security = object({
      enable_shielded_nodes       = bool
      enable_secure_boot          = bool
      enable_integrity_monitoring = bool
      enable_confidential_nodes   = bool
      pod_security_standards = object({
        mode    = string
        version = string
      })
    })
    monitoring = object({
      enable_managed_prometheus = bool
      logging_service           = string
      monitoring_service        = string
      logging_config = object({
        enable_components = list(string)
        retention_days    = number
      })
      monitoring_config = object({
        enable_components = list(string)
        managed_prometheus = object({
          enabled = bool
        })
      })
    })
    backup_config = object({
      enabled = bool
      schedule = object({
        incremental_interval = string
        full_interval        = string
        retention_days       = number
      })
    })
    database_encryption_key_name = optional(string)
  })

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.gke_config.cluster_name_suffix))
    error_message = "Cluster name suffix must be a valid GCP resource name."
  }

  validation {
    condition     = can(regex("^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}/[0-9]{1,2}$", var.gke_config.master_ipv4_cidr_block))
    error_message = "Master CIDR block must be a valid CIDR notation."
  }

  validation {
    condition = alltrue([
      for network in var.gke_config.master_authorized_networks :
      can(regex("^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}/[0-9]{1,2}$", network.cidr_block))
    ])
    error_message = "All authorized network CIDR blocks must be valid CIDR notation."
  }

  validation {
    condition     = var.gke_config.release_channel == "RAPID" || var.gke_config.release_channel == "REGULAR" || var.gke_config.release_channel == "STABLE"
    error_message = "Release channel must be one of: RAPID, REGULAR, STABLE."
  }

  validation {
    condition     = var.gke_config.monitoring.logging_config.retention_days >= 365
    error_message = "Log retention must be at least 1 year (365 days)."
  }

  validation {
    condition     = var.gke_config.backup_config.schedule.retention_days >= 1825
    error_message = "Backup retention must be at least 5 years (1825 days)."
  }
}

variable "gke_node_pools_config" {
  description = "GKE node pools configuration"
  type = map(object({
    name         = string
    node_count   = number
    machine_type = string
    disk_size_gb = number
    disk_type    = string
    zones        = list(string)
    autoscaling = object({
      min_node_count  = number
      max_node_count  = number
      location_policy = string
    })
    management = object({
      auto_repair  = bool
      auto_upgrade = bool
      maintenance_window = object({
        start_time = string
        end_time   = string
        recurrence = string
      })
    })
    labels = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
    security = object({
      enable_secure_boot            = bool
      enable_integrity_monitoring   = bool
      enable_confidential_computing = bool
    })
    workload_config = object({
      workload_identity_config = object({
        workload_pool = string
      })
      resource_limits   = map(string)
      resource_requests = map(string)
      pod_disruption_budget = object({
        min_available = number
      })
    })
  }))

  validation {
    condition = alltrue([
      for pool in var.gke_node_pools_config :
      pool.node_count >= 0 && pool.node_count <= 1000
    ])
    error_message = "Node count must be between 0 and 1000."
  }

  validation {
    condition = alltrue([
      for pool in var.gke_node_pools_config :
      pool.disk_size_gb >= 10 && pool.disk_size_gb <= 65536
    ])
    error_message = "Disk size must be between 10GB and 65536GB."
  }

  validation {
    condition = alltrue([
      for pool in var.gke_node_pools_config :
      pool.autoscaling.min_node_count <= pool.autoscaling.max_node_count &&
      pool.autoscaling.min_node_count >= 0 &&
      pool.autoscaling.max_node_count <= 30
    ])
    error_message = "Autoscaling must be between 0 and 30 nodes per pool."
  }

  validation {
    condition = alltrue([
      for pool in var.gke_node_pools_config :
      length(pool.zones) >= 3
    ])
    error_message = "Each node pool must span at least 3 zones."
  }
}

variable "gke_security_group" {
  description = "Security group for GKE RBAC"
  type        = string
  default     = "gke-security-groups@fintech.zone"
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default = {
    environment = "production"
    team        = "devops"
    cost_center = "devops"
    owner       = "devops"
    managed_by  = "terraform"
  }
}