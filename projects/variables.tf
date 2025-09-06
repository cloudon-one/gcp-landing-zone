variable "billing_account_id" {
  description = "The billing account ID to associate with the projects"
  type        = string
}

variable "folder_id" {
  description = "The folder ID where the projects will be created"
  type        = string
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "host_project_name" {
  description = "The name of the host project"
  type        = string
}

variable "host_project_apis" {
  description = "APIs to enable on host project"
  type        = list(string)
  default = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "servicenetworking.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "dns.googleapis.com"
  ]
}

variable "service_projects" {
  description = "Map of service projects to create"
  type = map(object({
    name = string
    type = string
    apis = optional(list(string), [])
  }))
  default = {}
}

variable "disable_default_network_creation" {
  description = "Whether to disable default network creation at folder level"
  type        = bool
  default     = true
}