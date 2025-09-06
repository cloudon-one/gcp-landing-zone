variable "organization_id" {
  description = "The organization ID where the VPC SC policy will be created"
  type        = string
}

variable "host_project_id" {
  description = "The host project ID for the VPC SC perimeter"
  type        = string
}

variable "gke_project_id" {
  description = "The GKE project ID to be included in the VPC SC perimeter"
  type        = string
}

variable "data_project_id" {
  description = "The data project ID to be included in the VPC SC perimeter"
  type        = string
}

variable "devops_team_members" {
  description = "List of DevOps team members (users and service accounts)"
  type        = list(string)
  default     = []
}

variable "backend_team_members" {
  description = "List of backend team members (users and service accounts)"
  type        = list(string)
  default     = []
}

variable "frontend_team_members" {
  description = "List of frontend team members (users and service accounts)"
  type        = list(string)
  default     = []
}

variable "mobile_team_members" {
  description = "List of mobile team members (users and service accounts)"
  type        = list(string)
  default     = []
}

variable "service_accounts" {
  description = "List of service accounts for access control"
  type        = list(string)
  default     = []
}

variable "gke_workload_identity_service_accounts" {
  description = "List of GKE workload identity service accounts"
  type        = list(string)
  default     = []
}

variable "iap_tunnel_users" {
  description = "List of IAP tunnel users"
  type        = list(string)
  default     = []
}

variable "restricted_services" {
  description = "List of restricted services for the main perimeter"
  type        = list(string)
  default     = []
}

variable "bridge_services" {
  description = "List of services for the bridge perimeter"
  type        = list(string)
  default     = []
}

variable "vpc_restricted_services" {
  description = "List of VPC-specific restricted services"
  type        = list(string)
  default     = []
} 