terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

resource "kubernetes_namespace" "gke_security_groups" {
  metadata {
    name = "gke-security-groups"
  }
}

resource "kubernetes_role_binding" "custom_secrets_admin" {
  for_each = toset([
    "backend",
    "frontend",
    "api",
    "workers",
    "monitoring"
  ])

  metadata {
    name      = "custom:secrets-admin"
    namespace = each.value
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "custom:secrets-admin"
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "devops@example.com"
    namespace = kubernetes_namespace.gke_security_groups.metadata[0].name
  }
}

resource "kubernetes_role_binding" "custom_pod_manager_backend" {
  for_each = toset([
    "backend",
    "api",
    "workers"
  ])

  metadata {
    name      = "custom:pod-manager"
    namespace = each.value
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "custom:pod-manager"
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "backend@example.com"
    namespace = kubernetes_namespace.gke_security_groups.metadata[0].name
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "devops@example.com"
    namespace = kubernetes_namespace.gke_security_groups.metadata[0].name
  }
}

resource "kubernetes_role_binding" "custom_pod_manager_frontend" {
  for_each = toset([
    "frontend"
  ])

  metadata {
    name      = "custom:pod-manager"
    namespace = each.value
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "custom:pod-manager"
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "frontend@example.com"
    namespace = kubernetes_namespace.gke_security_groups.metadata[0].name
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "devops@example.com"
    namespace = kubernetes_namespace.gke_security_groups.metadata[0].name
  }
}

resource "kubernetes_role_binding" "custom_pod_manager_mobile" {
  for_each = toset([
    "mobile"
  ])

  metadata {
    name      = "custom:pod-manager"
    namespace = each.value
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "custom:pod-manager"
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "mobile@example.com"
    namespace = kubernetes_namespace.gke_security_groups.metadata[0].name
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "devops@example.com"
    namespace = kubernetes_namespace.gke_security_groups.metadata[0].name
  }
}

resource "kubernetes_role_binding" "custom_deployment_manager" {
  for_each = toset([
    "backend",
    "frontend",
    "mobile",
    "api",
    "workers"
  ])

  metadata {
    name      = "custom:deployment-manager"
    namespace = each.value
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "custom:deployment-manager"
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "devops@example.com"
    namespace = kubernetes_namespace.gke_security_groups.metadata[0].name
  }

  dynamic "subject" {
    for_each = each.value == "backend" || each.value == "api" || each.value == "workers" ? [1] : []
    content {
      api_group = "rbac.authorization.k8s.io"
      kind      = "Group"
      name      = "backend@example.com"
      namespace = kubernetes_namespace.gke_security_groups.metadata[0].name
    }
  }

  dynamic "subject" {
    for_each = each.value == "frontend" ? [1] : []
    content {
      api_group = "rbac.authorization.k8s.io"
      kind      = "Group"
      name      = "frontend@example.com"
      namespace = kubernetes_namespace.gke_security_groups.metadata[0].name
    }
  }

  dynamic "subject" {
    for_each = each.value == "mobile" ? [1] : []
    content {
      api_group = "rbac.authorization.k8s.io"
      kind      = "Group"
      name      = "mobile@example.com"
      namespace = kubernetes_namespace.gke_security_groups.metadata[0].name
    }
  }
}

resource "kubernetes_role_binding" "custom_service_manager" {
  for_each = toset([
    "backend",
    "frontend",
    "mobile",
    "api",
    "workers"
  ])

  metadata {
    name      = "custom:service-manager"
    namespace = each.value
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "custom:service-manager"
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "devops@example.com"
    namespace = kubernetes_namespace.gke_security_groups.metadata[0].name
  }

  dynamic "subject" {
    for_each = each.value == "backend" || each.value == "api" || each.value == "workers" ? [1] : []
    content {
      api_group = "rbac.authorization.k8s.io"
      kind      = "Group"
      name      = "backend@example.com"
      namespace = kubernetes_namespace.gke_security_groups.metadata[0].name
    }
  }

  dynamic "subject" {
    for_each = each.value == "frontend" ? [1] : []
    content {
      api_group = "rbac.authorization.k8s.io"
      kind      = "Group"
      name      = "frontend@example.com"
      namespace = kubernetes_namespace.gke_security_groups.metadata[0].name
    }
  }

  dynamic "subject" {
    for_each = each.value == "mobile" ? [1] : []
    content {
      api_group = "rbac.authorization.k8s.io"
      kind      = "Group"
      name      = "mobile@example.com"
      namespace = kubernetes_namespace.gke_security_groups.metadata[0].name
    }
  }
}

resource "kubernetes_role_binding" "custom_configmap_manager" {
  for_each = toset([
    "backend",
    "frontend",
    "mobile",
    "api",
    "workers",
    "monitoring"
  ])

  metadata {
    name      = "custom:configmap-manager"
    namespace = each.value
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "custom:configmap-manager"
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "devops@example.com"
    namespace = kubernetes_namespace.gke_security_groups.metadata[0].name
  }

  dynamic "subject" {
    for_each = each.value == "backend" || each.value == "api" || each.value == "workers" ? [1] : []
    content {
      api_group = "rbac.authorization.k8s.io"
      kind      = "Group"
      name      = "backend@example.com"
      namespace = kubernetes_namespace.gke_security_groups.metadata[0].name
    }
  }

  dynamic "subject" {
    for_each = each.value == "frontend" ? [1] : []
    content {
      api_group = "rbac.authorization.k8s.io"
      kind      = "Group"
      name      = "frontend@example.com"
      namespace = kubernetes_namespace.gke_security_groups.metadata[0].name
    }
  }

  dynamic "subject" {
    for_each = each.value == "mobile" ? [1] : []
    content {
      api_group = "rbac.authorization.k8s.io"
      kind      = "Group"
      name      = "mobile@example.com"
      namespace = kubernetes_namespace.gke_security_groups.metadata[0].name
    }
  }
}

resource "kubernetes_cluster_role_binding" "custom_monitoring_viewer" {
  metadata {
    name = "custom:monitoring-viewer"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "custom:monitoring-viewer"
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "qa@example.com"
    namespace = kubernetes_namespace.gke_security_groups.metadata[0].name
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "devops@example.com"
    namespace = kubernetes_namespace.gke_security_groups.metadata[0].name
  }
}