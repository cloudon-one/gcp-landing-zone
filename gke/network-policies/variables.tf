variable "namespaces" {
  description = "List of namespaces to apply network policies to"
  type        = list(string)
  default     = ["backend", "frontend", "api", "workers", "mobile", "monitoring", "database", "production", "default"]
}

variable "allowed_ingress_ports" {
  description = "List of ports allowed for ingress traffic"
  type        = list(number)
  default     = [80, 443, 8080, 8443]
}

variable "allowed_egress_ports" {
  description = "List of ports allowed for egress traffic"
  type        = list(number)
  default     = [80, 443, 8080, 8443, 5432, 6379, 27017]
}

variable "monitoring_namespace" {
  description = "Namespace for monitoring components"
  type        = string
  default     = "monitoring"
}

variable "database_namespace" {
  description = "Namespace for database components"
  type        = string
  default     = "database"
}