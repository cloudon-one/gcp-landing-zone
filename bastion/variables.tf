
variable "net_svpc_backend_bucket" {
  description = "GCS bucket for net-svpc backend state"
  type        = string
  default     = "tfstate"
}

variable "net_svpc_backend_prefix" {
  description = "GCS prefix for net-svpc backend state"
  type        = string
  default     = "net-svpc"
}

variable "svc_projects_backend_bucket" {
  description = "GCS bucket for svc-projects backend state"
  type        = string
  default     = "tfstate-bucket"
}

variable "svc_projects_backend_prefix" {
  description = "GCS prefix for svc-projects backend state"
  type        = string
  default     = "svc-projects"
}

variable "region" {
  description = "The region where the bastion host will be created"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The zone where the bastion host will be created (a, b, c, etc.)"
  type        = string
  default     = "a"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "prod"
}

variable "service_account_name" {
  description = "Name for the bastion host service account"
  type        = string
  default     = "bastion"
}

variable "machine_type" {
  description = "The machine type for the bastion host"
  type        = string
  default     = "e2-medium"
}

variable "boot_image" {
  description = "The boot image for the bastion host"
  type        = string
  default     = "debian-cloud/debian-11"
}

variable "boot_disk_size_gb" {
  description = "The size of the boot disk in GB"
  type        = number
  default     = 20
}

variable "boot_disk_type" {
  description = "The type of the boot disk"
  type        = string
  default     = "pd-standard"
}

variable "authorized_networks" {
  description = "List of authorized network CIDR blocks for SSH access"
  type        = list(string)
  default     = []
}

variable "ssh_keys" {
  description = "Map of SSH public keys for user access"
  type        = map(string)
  default     = {}
}

variable "enable_iap_tunnel" {
  description = "Enable IAP tunnel access to the bastion host"
  type        = bool
  default     = true
}

variable "iap_user" {
  description = "The user email for IAP tunnel access"
  type        = string
  default     = "user1@example.com"
}

variable "enable_nat" {
  description = "Enable Cloud NAT for outbound internet access"
  type        = bool
  default     = false
}

variable "router_name" {
  description = "The name of the Cloud Router for NAT configuration"
  type        = string
  default     = ""
}

variable "deletion_protection" {
  description = "Enable deletion protection for the bastion host"
  type        = bool
  default     = true
}

variable "enable_os_login" {
  description = "Enable OS Login for centralized SSH access management"
  type        = bool
  default     = true
}

variable "os_login_users" {
  description = "List of IAM users to grant OS Login access (e.g., user:your-email@company.com)"
  type        = list(string)
  default     = []
}

variable "sa_impersonators" {
  description = "List of users/groups allowed to impersonate the bastion service account"
  type        = list(string)
  default     = []
}

variable "enable_https_proxy" {
  description = "Enable Squid HTTPS proxy on the bastion host"
  type        = bool
  default     = true
}

variable "proxy_port" {
  description = "The port for the HTTPS proxy to listen on"
  type        = number
  default     = 3128
}

variable "proxy_source_ranges" {
  description = "List of CIDR blocks allowed to use the HTTPS proxy"
  type        = list(string)
  default     = []
}

variable "additional_network_interfaces" {
  description = "List of additional network interfaces for multi-VPC access"
  type = list(object({
    vpc_name    = string
    subnet_name = string
  }))
  default = []
} 