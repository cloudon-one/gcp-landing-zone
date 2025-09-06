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


resource "kubernetes_labels" "kube_system_psa" {
  api_version = "v1"
  kind        = "Namespace"
  metadata {
    name = "kube-system"
  }
  labels = {
    "pod-security.kubernetes.io/enforce"         = "restricted"
    "pod-security.kubernetes.io/enforce-version" = var.pod_security_standards_config.version
    "pod-security.kubernetes.io/audit"           = "restricted"
    "pod-security.kubernetes.io/audit-version"   = var.pod_security_standards_config.version
    "pod-security.kubernetes.io/warn"            = "restricted"
    "pod-security.kubernetes.io/warn-version"    = var.pod_security_standards_config.version
  }
}

resource "kubernetes_labels" "default_psa" {
  api_version = "v1"
  kind        = "Namespace"
  metadata {
    name = "default"
  }
  labels = {
    "pod-security.kubernetes.io/enforce"         = "baseline"
    "pod-security.kubernetes.io/enforce-version" = var.pod_security_standards_config.version
    "pod-security.kubernetes.io/audit"           = "restricted"
    "pod-security.kubernetes.io/audit-version"   = var.pod_security_standards_config.version
    "pod-security.kubernetes.io/warn"            = "restricted"
    "pod-security.kubernetes.io/warn-version"    = var.pod_security_standards_config.version
  }
}

resource "kubernetes_labels" "monitoring_psa" {
  api_version = "v1"
  kind        = "Namespace"
  metadata {
    name = "monitoring"
  }
  labels = {
    "pod-security.kubernetes.io/enforce"         = "restricted"
    "pod-security.kubernetes.io/enforce-version" = var.pod_security_standards_config.version
    "pod-security.kubernetes.io/audit"           = "restricted"
    "pod-security.kubernetes.io/audit-version"   = var.pod_security_standards_config.version
    "pod-security.kubernetes.io/warn"            = "restricted"
    "pod-security.kubernetes.io/warn-version"    = var.pod_security_standards_config.version
  }
}

resource "kubernetes_namespace" "ingress_nginx_psa" {
  metadata {
    name = "ingress-nginx"
    labels = {
      "pod-security.kubernetes.io/enforce"         = "baseline"
      "pod-security.kubernetes.io/enforce-version" = var.pod_security_standards_config.version
      "pod-security.kubernetes.io/audit"           = "restricted"
      "pod-security.kubernetes.io/audit-version"   = var.pod_security_standards_config.version
      "pod-security.kubernetes.io/warn"            = "restricted"
      "pod-security.kubernetes.io/warn-version"    = var.pod_security_standards_config.version
    }
  }
}

resource "kubernetes_cluster_role" "pod_security_standards_viewer" {
  metadata {
    name = "pod-security-standards-viewer"
  }

  rule {
    api_groups = ["pod-security.kubernetes.io"]
    resources  = ["podsecuritystandards"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "pod_security_standards_viewer" {
  metadata {
    name = "pod-security-standards-viewer"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.pod_security_standards_viewer.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "default"
  }
}

resource "kubernetes_config_map" "pod_security_monitoring" {
  metadata {
    name      = "pod-security-monitoring"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"       = "pod-security-monitoring"
      "app.kubernetes.io/component"  = "monitoring"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  data = {
    "alert-rules.yaml" = <<-EOT
      groups:
      - name: pod-security-standards
        rules:
        - alert: PodSecurityStandardsViolation
          expr: increase(kube_pod_security_standards_violations_total[5m]) > 0
          for: 1m
          labels:
            severity: warning
            cluster: ${var.cluster_name}
            project: ${var.project_id}
          annotations:
            summary: "Pod Security Standards violation detected in cluster ${var.cluster_name}"
            description: "A pod has violated the configured Pod Security Standards in project ${var.project_id}"
            runbook_url: "https://kubernetes.io/docs/concepts/security/pod-security-standards/"
    EOT
  }
} 