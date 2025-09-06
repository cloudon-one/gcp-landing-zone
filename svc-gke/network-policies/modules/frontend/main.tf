terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

locals {
  namespace = "frontend"
}

resource "kubernetes_network_policy" "frontend_internal" {
  metadata {
    name      = "frontend-internal"
    namespace = local.namespace
  }

  spec {
    pod_selector {
      match_labels = {
        "app" = "frontend"
      }
    }
    policy_types = ["Ingress", "Egress"]

    ingress {
      from {
        pod_selector {
          match_labels = {
            "app" = "frontend"
          }
        }
      }
      ports {
        port     = 80
        protocol = "TCP"
      }
      ports {
        port     = 443
        protocol = "TCP"
      }
      ports {
        port     = 3000
        protocol = "TCP"
      }
    }

    egress {
      to {
        pod_selector {
          match_labels = {
            "app" = "frontend"
          }
        }
      }
      ports {
        port     = 80
        protocol = "TCP"
      }
      ports {
        port     = 443
        protocol = "TCP"
      }
      ports {
        port     = 3000
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
        "app" = "frontend"
      }
    }
    policy_types = ["Egress"]

    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "backend"
          }
        }
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

resource "kubernetes_network_policy" "frontend_to_api" {
  metadata {
    name      = "frontend-to-api"
    namespace = local.namespace
  }

  spec {
    pod_selector {
      match_labels = {
        "app" = "frontend"
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

resource "kubernetes_network_policy" "frontend_external_ingress" {
  metadata {
    name      = "frontend-external-ingress"
    namespace = local.namespace
  }

  spec {
    pod_selector {
      match_labels = {
        "app" = "frontend"
      }
    }
    policy_types = ["Ingress"]

    ingress {
      ports {
        port     = 80
        protocol = "TCP"
      }
      ports {
        port     = 443
        protocol = "TCP"
      }
      ports {
        port     = 3000
        protocol = "TCP"
      }
    }
  }
}

resource "kubernetes_network_policy" "frontend_to_monitoring" {
  metadata {
    name      = "frontend-to-monitoring"
    namespace = local.namespace
  }

  spec {
    pod_selector {
      match_labels = {
        "app" = "frontend"
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
  }
} 