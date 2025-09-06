terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

locals {
  namespace               = "database"
  cloudsql_private_ips    = ["10.161.1.0/24", "10.161.2.0/24"]
  memorystore_private_ips = ["10.161.12.0/24"]
}

resource "kubernetes_network_policy" "database_tools" {
  metadata {
    name      = "database-tools"
    namespace = local.namespace
  }

  spec {
    pod_selector {
      match_labels = {
        "app" = "db-admin"
      }
    }
    policy_types = ["Egress"]

    egress {
      to {
        ip_block {
          cidr = local.cloudsql_private_ips[0]
        }
      }
      ports {
        port     = 5432
        protocol = "TCP"
      }
    }

    egress {
      to {
        ip_block {
          cidr = local.cloudsql_private_ips[1]
        }
      }
      ports {
        port     = 5432
        protocol = "TCP"
      }
    }

    egress {
      to {
        ip_block {
          cidr = local.memorystore_private_ips[0]
        }
      }
      ports {
        port     = 6379
        protocol = "TCP"
      }
    }
  }
} 