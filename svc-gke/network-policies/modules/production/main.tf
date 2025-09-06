terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

locals {
  namespace = "production"
}

resource "kubernetes_network_policy" "production_internal" {
  metadata {
    name      = "production-internal"
    namespace = local.namespace
  }

  spec {
    pod_selector {
      match_labels = {
        "app" = "app"
      }
    }
    policy_types = ["Ingress", "Egress"]

    ingress {
      from {
        pod_selector {
          match_labels = {
            "app" = "app"
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
            "app" = "app"
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

resource "kubernetes_network_policy" "production_to_api" {
  metadata {
    name      = "production-to-api"
    namespace = local.namespace
  }

  spec {
    pod_selector {
      match_labels = {
        "app" = "app"
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

resource "kubernetes_network_policy" "production_to_monitoring" {
  metadata {
    name      = "production-to-monitoring"
    namespace = local.namespace
  }

  spec {
    pod_selector {
      match_labels = {
        "app" = "app"
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

resource "kubernetes_network_policy" "production_external_ingress" {
  metadata {
    name      = "production-external-ingress"
    namespace = local.namespace
  }

  spec {
    pod_selector {
      match_labels = {
        "app" = "app"
      }
    }
    policy_types = ["Ingress"]

    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "ingress-nginx"
          }
        }
        pod_selector {
          match_labels = {
            "app.kubernetes.io/name" = "ingress-nginx"
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

resource "kubernetes_network_policy" "production_to_database" {
  metadata {
    name      = "production-to-database"
    namespace = local.namespace
  }

  spec {
    pod_selector {
      match_labels = {
        "app" = "app"
      }
    }
    policy_types = ["Egress"]

    egress {
      to {
        ip_block {
          cidr = "10.161.1.0/24"
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

    egress {
      to {
        ip_block {
          cidr = "10.161.12.0/28"
        }
      }
      ports {
        port     = 6379
        protocol = "TCP"
      }
    }
  }
}

resource "kubernetes_network_policy" "production_to_gcp_services" {
  metadata {
    name      = "production-to-gcp-services"
    namespace = local.namespace
  }

  spec {
    pod_selector {
      match_labels = {
        "app" = "app"
      }
    }
    policy_types = ["Egress"]

    egress {
      to {
        ip_block {
          cidr   = "0.0.0.0/0"
          except = ["10.160.0.0/16", "10.161.128.0/17", "10.161.0.0/16", "10.161.12.0/28", "10.161.1.0/24", "10.161.2.0/24"]
        }
      }
      ports {
        port     = 443
        protocol = "TCP"
      }
    }

    egress {
      to {
        ip_block {
          cidr   = "0.0.0.0/0"
          except = ["10.160.0.0/16", "10.160.128.0/17", "10.161.0.0/16", "10.161.12.0/28", "10.161.1.0/24", "10.161.2.0/24"]
        }
      }
      ports {
        port     = 443
        protocol = "TCP"
      }
    }
  }
}