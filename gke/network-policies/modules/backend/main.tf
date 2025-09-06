terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

locals {
  namespace = "backend"
}
resource "kubernetes_network_policy" "backend_internal" {
  metadata {
    name      = "backend-internal"
    namespace = local.namespace
  }

  spec {
    pod_selector {
      match_labels = {
        "app" = "backend"
      }
    }
    policy_types = ["Ingress", "Egress"]

    ingress {
      from {
        pod_selector {
          match_labels = {
            "app" = "backend"
          }
        }
      }
      ports {
        port     = 8080
        protocol = "TCP"
      }
      ports {
        port     = 8443
        protocol = "TCP"
      }
    }

    egress {
      to {
        pod_selector {
          match_labels = {
            "app" = "backend"
          }
        }
      }
      ports {
        port     = 8080
        protocol = "TCP"
      }
      ports {
        port     = 8443
        protocol = "TCP"
      }
    }
  }
}

resource "kubernetes_network_policy" "backend_to_api" {
  metadata {
    name      = "backend-to-api"
    namespace = local.namespace
  }

  spec {
    pod_selector {
      match_labels = {
        "app" = "backend"
      }
    }
    policy_types = ["Egress"]

    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "api"
          }
        }
        pod_selector {
          match_labels = {
            "app" = "api"
          }
        }
      }
      ports {
        port     = 8080
        protocol = "TCP"
      }
      ports {
        port     = 8443
        protocol = "TCP"
      }
    }
  }
}

resource "kubernetes_network_policy" "backend_to_monitoring" {
  metadata {
    name      = "backend-to-monitoring"
    namespace = local.namespace
  }

  spec {
    pod_selector {
      match_labels = {
        "app" = "backend"
      }
    }
    policy_types = ["Egress"]

    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "monitoring"
          }
        }
        pod_selector {
          match_labels = {
            "app" = "prometheus"
          }
        }
      }
      ports {
        port     = 9090
        protocol = "TCP"
      }
    }

    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "monitoring"
          }
        }
        pod_selector {
          match_labels = {
            "app" = "jaeger"
          }
        }
      }
      ports {
        port     = 14268
        protocol = "TCP"
      }
    }
  }
}

resource "kubernetes_network_policy" "frontend_to_backend" {
  metadata {
    name      = "frontend-to-backend"
    namespace = local.namespace
  }

  spec {
    pod_selector {
      match_labels = {
        "app" = "backend"
      }
    }
    policy_types = ["Ingress"]

    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "frontend"
          }
        }
        pod_selector {
          match_labels = {
            "app" = "frontend"
          }
        }
      }
      ports {
        port     = 8080
        protocol = "TCP"
      }
      ports {
        port     = 8443
        protocol = "TCP"
      }
    }
  }
}

resource "kubernetes_network_policy" "backend_to_database" {
  metadata {
    name      = "backend-to-database"
    namespace = local.namespace
  }

  spec {
    pod_selector {
      match_labels = {
        "app" = "backend"
      }
    }
    policy_types = ["Egress"]

    # Allow access to CloudSQL
    egress {
      to {
        ip_block {
          cidr = "10.61.1.0/24"
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
          cidr = "10.161.2.0/24"
        }
      }
      ports {
        port     = 5432
        protocol = "TCP"
      }
    }

    # Allow access to Memorystore Redis
    egress {
      to {
        ip_block {
          cidr = "10.161.12.0/24"
        }
      }
      ports {
        port     = 6379
        protocol = "TCP"
      }
    }
  }
} 