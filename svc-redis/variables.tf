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
  description = "Additional labels to apply to resources"
  type        = map(string)
  default     = {}
}

variable "redis_config" {
  description = "Redis configuration"
  type = object({
    instance_name_suffix = string
  })
  default = {
    instance_name_suffix = ""
  }
}

variable "redis_instances_config" {
  description = "Configuration for Redis instances"
  type = map(object({
    tier           = string
    memory_size_gb = number
    redis_version  = string
    replica_count  = number
    redis_configs  = map(string)
  }))
  default = {
    main = {
      tier           = "STANDARD_HA"
      memory_size_gb = 5
      redis_version  = "REDIS_7_0"
      replica_count  = 1
      redis_configs = {
        maxmemory-policy = "allkeys-lru"
        timeout          = "300"
      }
    }
  }
} 