variable "region" {
  description = "GCP region"
  type        = string
  default     = "europe-central2"
}

variable "net_svpc_backend_bucket" {
  description = "Backend bucket for net-svcp state"
  type        = string
  default     = "tfstate-bucket"
}

variable "net_svpc_backend_prefix" {
  description = "Backend prefix for net-svpc state"
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

variable "enable_gke_iam" {
  description = "Enable GKE IAM resources"
  type        = bool
  default     = true
}

variable "enable_sql_iam" {
  description = "Enable Cloud SQL IAM resources"
  type        = bool
  default     = true
}

variable "gke_workload_identity_service_accounts" {
  description = "GKE workload identity service accounts configuration"
  type = map(object({
    display_name               = string
    description                = optional(string)
    kubernetes_namespace       = string
    kubernetes_service_account = string
    gcp_roles                  = list(string)
  }))
  default = {}
}

variable "gke_service_account_config" {
  description = "GKE service account configuration"
  type = object({
    account_id   = string
    display_name = string
    description  = optional(string)
    gcp_roles    = list(string)
  })
  default = {
    account_id   = "gke-service-account"
    display_name = "GKE Service Account"
    description  = ""
    gcp_roles = [
      "roles/container.nodeServiceAccount",
      "roles/container.serviceAgent",
      "roles/container.developer",
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
      "roles/monitoring.viewer",
      "roles/stackdriver.resourceMetadata.writer"
    ]
  }
}

variable "enable_os_login_iam" {
  description = "Enable OS Login IAM resources"
  type        = bool
  default     = false
}

variable "os_login_users" {
  description = "List of IAM users to grant OS Login access (e.g., user:your-email@company.com)"
  type        = list(string)
  default     = []
}

variable "enable_bastion_iam" {
  description = "Enable Bastion IAM resources"
  type        = bool
  default     = false
}

variable "bastion_service_account_config" {
  description = "Bastion service account configuration"
  type = object({
    account_id   = string
    display_name = string
    description  = optional(string)
    gcp_roles    = list(string)
  })
  default = {
    account_id   = "bastion"
    display_name = "Bastion Admin Service Account"
    description  = "Service account for bastion host with admin access to GCP resources"
    gcp_roles = [
      "roles/container.admin",
      "roles/container.clusterAdmin",
      "roles/container.developer",
      "roles/cloudsql.admin",
      "roles/cloudsql.client",
      "roles/cloudsql.instanceUser",
      "roles/storage.admin",
      "roles/storage.objectAdmin",
      "roles/redis.admin",
      "roles/redis.editor",
      "roles/compute.loadBalancerAdmin",
      "roles/compute.networkAdmin",
      "roles/compute.securityAdmin",
      "roles/compute.instanceAdmin",
      "roles/iam.serviceAccountUser",
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
      "roles/monitoring.viewer"
    ]
  }
}

variable "existing_bastion_service_account" {
  description = "Existing bastion service account email to use instead of creating a new one"
  type        = string
  default     = "bastion-prod-host@host-project-8hhr.iam.gserviceaccount.com"
}

variable "enable_iap_tunnel_iam" {
  description = "Enable IAP Tunnel IAM resources"
  type        = bool
  default     = false
}

variable "iap_tunnel_users" {
  description = "List of IAM users to grant IAP Tunnel access (e.g., user:your-email@company.com)"
  type        = list(string)
  default     = []
} 