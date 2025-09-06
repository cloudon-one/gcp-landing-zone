variable "region" {
  description = "The GCP region where the GKE cluster is located"
  type        = string
}

variable "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "pod_security_standards_config" {
  description = "Pod Security Standards configuration"
  type = object({
    mode    = string
    version = string
  })
  default = {
    mode    = "ENFORCED"
    version = "v1.32"
  }
}

variable "project_id" {
  description = "The GCP project ID where the GKE cluster is located"
  type        = string
}

variable "cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
} 