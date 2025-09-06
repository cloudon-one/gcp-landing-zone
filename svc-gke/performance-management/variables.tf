variable "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "performance_config" {
  description = "Performance configuration"
  type = object({
    enable_burst_scaling          = bool
    enable_node_auto_provisioning = bool
    load_testing_enabled          = bool
    max_burst_capacity            = number
  })
  default = {
    enable_burst_scaling          = true
    enable_node_auto_provisioning = true
    load_testing_enabled          = false
    max_burst_capacity            = 50
  }
} 