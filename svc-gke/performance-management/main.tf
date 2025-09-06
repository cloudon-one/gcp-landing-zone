
terraform {
  required_version = ">= 1.5"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

resource "kubernetes_resource_quota" "default_quota" {
  metadata {
    name      = "default-quota"
    namespace = "default"
  }

  spec {
    hard = {
      "requests.cpu"    = "8"
      "requests.memory" = "16Gi"
      "limits.cpu"      = "16"
      "limits.memory"   = "32Gi"
      "pods"            = "20"
    }
  }
}

resource "kubernetes_resource_quota" "production_quota" {
  metadata {
    name      = "production-quota"
    namespace = "production"
  }

  spec {
    hard = {
      "requests.cpu"    = "16"
      "requests.memory" = "32Gi"
      "limits.cpu"      = "32"
      "limits.memory"   = "64Gi"
      "pods"            = "40"
    }
  }
}

resource "kubernetes_resource_quota" "monitoring_quota" {
  metadata {
    name      = "monitoring-quota"
    namespace = "monitoring"
  }

  spec {
    hard = {
      "requests.cpu"    = "4"
      "requests.memory" = "8Gi"
      "limits.cpu"      = "8"
      "limits.memory"   = "16Gi"
      "pods"            = "10"
    }
  }
}

resource "kubernetes_limit_range" "default_limits" {
  metadata {
    name      = "default-limits"
    namespace = "default"
  }

  spec {
    limit {
      type = "Container"
      default = {
        cpu    = "500m"
        memory = "1Gi"
      }
      default_request = {
        cpu    = "250m"
        memory = "512Mi"
      }
      max = {
        cpu    = "2"
        memory = "4Gi"
      }
      min = {
        cpu    = "100m"
        memory = "128Mi"
      }
    }
  }
}

resource "kubernetes_limit_range" "production_limits" {
  metadata {
    name      = "production-limits"
    namespace = "production"
  }

  spec {
    limit {
      type = "Container"
      default = {
        cpu    = "1"
        memory = "2Gi"
      }
      default_request = {
        cpu    = "500m"
        memory = "1Gi"
      }
      max = {
        cpu    = "4"
        memory = "8Gi"
      }
      min = {
        cpu    = "200m"
        memory = "256Mi"
      }
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "app_hpa" {
  metadata {
    name      = "app-hpa"
    namespace = "production"
  }

  spec {
    max_replicas                      = 10
    min_replicas                      = 3
    target_cpu_utilization_percentage = 70

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = "app"
    }

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 70
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = 80
        }
      }
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "api_hpa" {
  metadata {
    name      = "api-hpa"
    namespace = "production"
  }

  spec {
    max_replicas                      = 15
    min_replicas                      = 5
    target_cpu_utilization_percentage = 75

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = "api"
    }

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 75
        }
      }
    }
  }
}

resource "kubernetes_pod_disruption_budget_v1" "app_pdb" {
  metadata {
    name      = "app-pdb"
    namespace = "production"
  }

  spec {
    min_available = 2
    selector {
      match_labels = {
        app = "app"
      }
    }
  }
}

resource "kubernetes_pod_disruption_budget_v1" "api_pdb" {
  metadata {
    name      = "api-pdb"
    namespace = "production"
  }

  spec {
    min_available = 3
    selector {
      match_labels = {
        app = "api"
      }
    }
  }
}

resource "kubernetes_pod_disruption_budget_v1" "monitoring_pdb" {
  metadata {
    name      = "monitoring-pdb"
    namespace = "monitoring"
  }

  spec {
    min_available = 1
    selector {
      match_labels = {
        app = "prometheus"
      }
    }
  }
}

resource "kubernetes_priority_class_v1" "high_priority" {
  metadata {
    name = "high-priority"
  }
  value          = 1000000
  global_default = false
  description    = "High priority class for critical workloads"
}

resource "kubernetes_priority_class_v1" "medium_priority" {
  metadata {
    name = "medium-priority"
  }
  value          = 500000
  global_default = true
  description    = "Medium priority class for standard workloads"
}

resource "kubernetes_priority_class_v1" "low_priority" {
  metadata {
    name = "low-priority"
  }
  value          = 100000
  global_default = false
  description    = "Low priority class for batch jobs"
}

resource "kubernetes_network_policy" "performance_isolation" {
  metadata {
    name      = "performance-isolation"
    namespace = "production"
  }

  spec {
    pod_selector {
      match_labels = {
        app = "app"
      }
    }

    policy_types = ["Ingress", "Egress"]

    ingress {
      from {
        pod_selector {
          match_labels = {
            app = "api"
          }
        }
      }
      ports {
        protocol = "TCP"
        port     = 8080
      }
    }

    egress {
      to {
        namespace_selector {
          match_labels = {
            name = "monitoring"
          }
        }
      }
      ports {
        protocol = "TCP"
        port     = 9090
      }
    }
  }
}

resource "kubernetes_config_map" "performance_monitoring" {
  metadata {
    name      = "performance-monitoring"
    namespace = "monitoring"
  }

  data = {
    "prometheus-rules.yaml" = <<-EOT
      groups:
      - name: performance-alerts
        rules:
        - alert: HighCPUUtilization
          expr: avg(rate(container_cpu_usage_seconds_total{container!=""}[5m])) by (pod) > 0.8
          for: 2m
          labels:
            severity: warning
          annotations:
            summary: "High CPU utilization detected"
            description: "Pod {{ $labels.pod }} has high CPU utilization"

        - alert: HighMemoryUtilization
          expr: avg(rate(container_memory_usage_bytes{container!=""}[5m])) by (pod) > 0.85
          for: 2m
          labels:
            severity: warning
          annotations:
            summary: "High memory utilization detected"
            description: "Pod {{ $labels.pod }} has high memory utilization"

        - alert: NodePressure
          expr: kubelet_node_name{job="kubelet"} and on(node) (kube_node_status_condition{condition="MemoryPressure",status="true"} or kube_node_status_condition{condition="DiskPressure",status="true"})
          for: 1m
          labels:
            severity: critical
          annotations:
            summary: "Node under pressure"
            description: "Node {{ $labels.node }} is under memory or disk pressure"

        - alert: HPAAtMaxReplicas
          expr: kube_horizontalpodautoscaler_status_current_replicas / kube_horizontalpodautoscaler_spec_target_metric{metric_name="cpu"} > 0.9
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "HPA at maximum replicas"
            description: "HPA {{ $labels.horizontalpodautoscaler }} is at maximum replicas"
    EOT
  }
} 