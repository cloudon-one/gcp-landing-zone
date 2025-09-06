locals {
  folder_id = "12345678901234567890" # Replace with your actual folder ID
  prefix    = "dev"
  suffix    = random_string.suffix.result
  region    = var.region

  host_project_name      = "${local.prefix}-svpc-host-${local.suffix}"
  gke_project_name       = "${local.prefix}-gke-svc-${local.suffix}"
  data_project_name      = "${local.prefix}-data-svc-${local.suffix}"
  gke_vpc_cidr           = "10.160.0.0/16"
  gke_subnet_cidr        = "10.160.4.0/22"   # Nodes subnet
  gke_control_plane_cidr = "10.160.1.0/28"   # GKE control plane
  gke_proxy_cidr         = "10.160.0.0/24"   # Proxy-only subnet for ILB
  gke_pods_cidr          = "10.160.128.0/17" # Pod secondary range
  gke_services_cidr      = "10.160.8.0/22"   # Service secondary range

  data_vpc_cidr               = "10.161.0.0/16"
  data_subnet_cidr            = "10.161.4.0/22"   # Data services subnet
  data_proxy_cidr             = "10.161.0.0/24"   # Proxy-only subnet for ILB
  data_cloudsql_cidr          = "10.161.1.0/24"   # Cloud SQL private connection
  data_composer_pods_cidr     = "10.161.128.0/17" # Composer pods secondary range
  data_composer_services_cidr = "10.161.8.0/22"   # Composer services secondary range

  common_labels = merge(var.labels, {
    environment     = "production"
    project         = "prod"
    managed_by      = "terraform"
    deployment_date = formatdate("YYYY-MM-DD", timestamp())
    folder_id       = local.folder_id
    region          = local.region
  })

  project_labels = {
    host = merge(local.common_labels, {
      project_type = "host"
      vpc_type     = "shared"
      role         = "network-hub"
    })
    gke = merge(local.common_labels, {
      project_type = "service"
      workload     = "gke"
      role         = "compute"
    })
    data = merge(local.common_labels, {
      project_type = "service"
      workload     = "data"
      role         = "analytics"
    })
  }

  host_project_apis = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "servicenetworking.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "dns.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com"
  ]

  gke_project_apis = [
    "container.googleapis.com",
    "compute.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "cloudtrace.googleapis.com",
    "clouddebugger.googleapis.com"
  ]

  data_project_apis = [
    "compute.googleapis.com",
    "dataflow.googleapis.com",
    "composer.googleapis.com",
    "bigquery.googleapis.com",
    "storage.googleapis.com",
    "sql-component.googleapis.com",
    "sqladmin.googleapis.com",
    "pubsub.googleapis.com",
    "dataproc.googleapis.com"
  ]
}

resource "random_string" "suffix" {
  length  = 4
  lower   = true
  upper   = false
  special = false
}