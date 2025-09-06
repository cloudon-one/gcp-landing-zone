terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

locals {
  namespaces = ["backend", "frontend", "api", "workers", "mobile", "monitoring", "database", "production", "default"]
}

resource "kubernetes_network_policy" "default_deny_ingress" {
  for_each = toset(local.namespaces)

  metadata {
    name      = "default-deny-ingress"
    namespace = each.value
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]

    # No ingress rules = deny all ingress traffic
  }
}

resource "kubernetes_network_policy" "default_deny_egress" {
  for_each = toset(local.namespaces)

  metadata {
    name      = "default-deny-egress"
    namespace = each.value
  }

  spec {
    pod_selector {}
    policy_types = ["Egress"]

    # No egress rules = deny all egress traffic
  }
}

resource "kubernetes_network_policy" "allow_dns" {
  for_each = toset(local.namespaces)

  metadata {
    name      = "allow-dns"
    namespace = each.value
  }

  spec {
    pod_selector {}
    policy_types = ["Egress"]

    # Allow DNS to CoreDNS
    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "kube-system"
          }
        }
        pod_selector {
          match_labels = {
            "k8s-app" = "kube-dns"
          }
        }
      }
      ports {
        port     = 53
        protocol = "UDP"
      }
      ports {
        port     = 53
        protocol = "TCP"
      }
    }

    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "kube-system"
          }
        }
        pod_selector {
          match_labels = {
            "k8s-app" = "node-local-dns"
          }
        }
      }
      ports {
        port     = 53
        protocol = "UDP"
      }
      ports {
        port     = 53
        protocol = "TCP"
      }
    }

    egress {
      to {
        ip_block {
          cidr = "169.254.20.10/32"
        }
      }
      ports {
        port     = 53
        protocol = "UDP"
      }
      ports {
        port     = 53
        protocol = "TCP"
      }
    }
  }
} 