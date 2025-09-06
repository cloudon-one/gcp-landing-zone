variable "region" {
  description = "The region to deploy to"
  type        = string
  default     = "us-central1"
}

variable "net_svpc_backend_bucket" {
  description = "Backend bucket for net-svcp state"
  type        = string
  default     = "tfstate-bucket"
}

variable "net_svpc_backend_prefix" {
  description = "Backend prefix for net-svcp state"
  type        = string
  default     = "net-svpc"
}

variable "svc_projects_backend_bucket" {
  description = "Backend bucket for svc-projects state"
  type        = string
  default     = "tfstate-bucket"
}

variable "svc_projects_backend_prefix" {
  description = "Backend prefix for svc-projects state"
  type        = string
  default     = "svc-projects"
}

variable "net_iam_backend_bucket" {
  description = "Backend bucket for net-iam state"
  type        = string
  default     = "tfstate-bucket"
}

variable "net_iam_backend_prefix" {
  description = "Backend prefix for net-iam state"
  type        = string
  default     = "net-iam"
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "sql_config" {
  description = "Cloud SQL configuration"
  type = object({
    enabled                = bool
    instance_name_suffix   = string
    create_service_account = bool
    master_authorized_networks = list(object({
      name  = string
      value = string
    }))
  })
  default = {
    enabled                    = true
    instance_name_suffix       = ""
    create_service_account     = true
    master_authorized_networks = []
  }
}

variable "sql_instances_config" {
  description = "Map of Cloud SQL instances to create"
  type = map(object({
    database_version      = string
    machine_type          = string
    disk_type             = string
    disk_size             = number
    disk_autoresize       = bool
    disk_autoresize_limit = number
    availability_type     = string
    primary_zone          = string
    deletion_protection   = bool
    database_flags = list(object({
      name  = string
      value = string
    }))
    databases = map(object({
      name      = string
      charset   = optional(string)
      collation = optional(string)
    }))
    users = map(object({
      name     = string
      host     = optional(string)
      password = optional(string)
    }))
    read_replicas = map(object({
      region                = string
      zone                  = string
      machine_type          = string
      disk_type             = string
      disk_size             = number
      disk_autoresize       = bool
      disk_autoresize_limit = number
      deletion_protection   = bool
      ip_configuration = object({
        ipv4_enabled    = bool
        private_network = string
        require_ssl     = bool
        authorized_networks = list(object({
          name  = string
          value = string
        }))
      })
    }))
  }))
  default = {

    "analytics" = {
      database_version      = "POSTGRES_16"
      machine_type          = "db-perf-optimized-N-4"
      disk_type             = "PD_SSD"
      disk_size             = 250
      disk_autoresize       = true
      disk_autoresize_limit = 0
      availability_type     = "REGIONAL"
      primary_zone          = "us-central1-b"
      deletion_protection   = false
      database_flags = [
        {
          name  = "cloudsql.iam_authentication"
          value = "on"
        },
        {
          name  = "max_connections"
          value = "200"
        },
        {
          name  = "shared_buffers"
          value = "2516582"
        }
      ]
      databases = {
        analytics_db = {
          name      = "analytics"
          charset   = "UTF8"
          collation = "en_US.UTF8"
        }
        reporting_db = {
          name      = "reporting"
          charset   = "UTF8"
          collation = "en_US.UTF8"
        }
      }
      users = {
        analytics_user = {
          name     = "analytics_user"
          host     = "%"
          password = null # Set via terraform.tfvars
        }
        reporting_user = {
          name     = "reporting_user"
          host     = "%"
          password = null # Set via terraform.tfvars
        }
      }
      read_replicas = {
        "replica" = {
          region                = "us-west3"
          zone                  = "us-west3-a"
          machine_type          = "db-perf-optimized-N-2"
          disk_type             = "PD_SSD"
          disk_size             = 250
          disk_autoresize       = true
          disk_autoresize_limit = 0
          deletion_protection   = false
          ip_configuration = {
            ipv4_enabled        = false
            private_network     = null # Will be set from data source
            require_ssl         = true
            authorized_networks = []
          }
        }
      }
    }
  }
} 