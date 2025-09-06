terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

locals {
  namespace = "default"
}

resource "kubernetes_network_policy" "data_processor_internal" {
  metadata {
    name      = "data-processor-internal"
    namespace = local.namespace
  }

  spec {
    pod_selector {
      match_labels = {
        "app" = "data-processor"
      }
    }
    policy_types = ["Ingress", "Egress"]

    ingress {
      from {
        pod_selector {
          match_labels = {
            "app" = "data-processor"
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
            "app" = "data-processor"
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

resource "kubernetes_network_policy" "data_processor_to_monitoring" {
  metadata {
    name      = "data-processor-to-monitoring"
    namespace = local.namespace
  }

  spec {
    pod_selector {
      match_labels = {
        "app" = "data-processor"
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

resource "kubernetes_network_policy" "data_processor_to_database" {
  metadata {
    name      = "data-processor-to-database"
    namespace = local.namespace
  }

  spec {
    pod_selector {
      match_labels = {
        "app" = "data-processor"
      }
    }
    policy_types = ["Egress"]

    # Allow access to CloudSQL
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

resource "kubernetes_network_policy" "data_processor_to_bigquery" {
  metadata {
    name      = "data-processor-to-bigquery"
    namespace = local.namespace
  }

  spec {
    pod_selector {
      match_labels = {
        "app" = "data-processor"
      }
    }
    policy_types = ["Egress"]
    egress {
      to {
        ip_block {
          cidr   = "0.0.0.0/0"
          except = ["10.160.0.0/16", "10.161.0.0/16"]
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
          except = ["10.160.0.0/16", "10.161.0.0/16"]
        }
      }
      ports {
        port     = 80
        protocol = "TCP"
      }
    }
  }
}

resource "kubernetes_network_policy" "data_processor_cronjobs" {
  metadata {
    name      = "data-processor-cronjobs"
    namespace = local.namespace
  }

  spec {
    pod_selector {
      match_labels = {
        "app"      = "data-processor"
        "job-type" = "cronjob"
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