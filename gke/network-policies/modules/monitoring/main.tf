terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

locals {
  namespace = "monitoring"
}

resource "kubernetes_network_policy" "monitoring_internal" {
  metadata {
    name      = "monitoring-internal"
    namespace = local.namespace
  }

  spec {
    pod_selector {
      match_labels = {
        "app" = "prometheus"
      }
    }
    policy_types = ["Ingress", "Egress"]

    ingress {
      from {
        pod_selector {
          match_labels = {
            "app" = "prometheus"
          }
        }
      }
      from {
        pod_selector {
          match_labels = {
            "app" = "grafana"
          }
        }
      }
      from {
        pod_selector {
          match_labels = {
            "app" = "jaeger"
          }
        }
      }
      ports {
        port     = 9090
        protocol = "TCP"
      }
      ports {
        port     = 3000
        protocol = "TCP"
      }
      ports {
        port     = 14268
        protocol = "TCP"
      }
    }

    egress {
      to {
        pod_selector {
          match_labels = {
            "app" = "prometheus"
          }
        }
      }
      to {
        pod_selector {
          match_labels = {
            "app" = "grafana"
          }
        }
      }
      to {
        pod_selector {
          match_labels = {
            "app" = "jaeger"
          }
        }
      }
      ports {
        port     = 9090
        protocol = "TCP"
      }
      ports {
        port     = 3000
        protocol = "TCP"
      }
      ports {
        port     = 14268
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
        "app" = "prometheus"
      }
    }
    policy_types = ["Ingress"]

    ingress {
      from {
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
        port     = 9090
        protocol = "TCP"
      }
    }
  }
}

resource "kubernetes_network_policy" "api_to_monitoring" {
  metadata {
    name      = "api-to-monitoring"
    namespace = local.namespace
  }

  spec {
    pod_selector {
      match_labels = {
        "app" = "prometheus"
      }
    }
    policy_types = ["Ingress"]

    ingress {
      from {
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
        port     = 9090
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
        "app" = "prometheus"
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
        port     = 9090
        protocol = "TCP"
      }
    }
  }
}

resource "kubernetes_network_policy" "jaeger_ingress" {
  metadata {
    name      = "jaeger-ingress"
    namespace = local.namespace
  }

  spec {
    pod_selector {
      match_labels = {
        "app" = "jaeger"
      }
    }
    policy_types = ["Ingress"]

    ingress {
      from {
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
      from {
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
        port     = 14268
        protocol = "TCP"
      }
    }
  }
}

resource "kubernetes_network_policy" "grafana_external" {
  metadata {
    name      = "grafana-external"
    namespace = local.namespace
  }

  spec {
    pod_selector {
      match_labels = {
        "app" = "grafana"
      }
    }
    policy_types = ["Ingress"]

    ingress {
      ports {
        port     = 3000
        protocol = "TCP"
      }
    }
  }
} 