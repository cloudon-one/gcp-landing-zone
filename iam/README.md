# Network IAM Management

This Terraform configuration manages Identity and Access Management (IAM) resources for the fintech production infrastructure across multiple Google Cloud projects.

## Overview

The `net-iam` module provides centralized IAM management for:

- **GKE (Google Kubernetes Engine)** service accounts and workload identity
- **Cloud SQL** database access and administration
- **OS Login** for secure SSH access to compute instances
- **Bastion Host** administration and access control
- **IAP (Identity-Aware Proxy) Tunnel** access for secure connectivity

## Architecture

This module integrates with the broader fintech infrastructure by consuming outputs from:

- `net-svpc` - Shared VPC network configuration
- `svc-projects` - Project IDs and service account information

## Components

### 1. GKE IAM Resources

- **Host Service Agent**: Manages GKE cluster operations
- **Workload Identity**: Enables Kubernetes service accounts to access Google Cloud APIs
- **Node Service Account**: Provides necessary permissions for GKE nodes

### 2. Cloud SQL IAM Resources

- **Admin Service Account**: Full database administration capabilities
- **Client Service Account**: Application-level database access

### 3. OS Login IAM

- **User Access**: Grants secure SSH access to compute instances
- **Two-Factor Authentication**: Enhanced security for remote access

### 4. Bastion Host IAM

- **Service Account**: Dedicated service account for bastion host operations
- **Admin Permissions**: Comprehensive access for infrastructure management

### 5. IAP Tunnel IAM

- **Tunnel Access**: Secure access to private resources via Identity-Aware Proxy
- **User Management**: Controlled access for authorized personnel

## Usage

### Basic Configuration

```hcl
module "iam" {
  source = "./net-iam"

  # Enable all IAM components
  enable_gke_iam = true
  enable_sql_iam = true
  enable_os_login_iam = true
  enable_bastion_iam = true
  enable_iap_tunnel_iam = true

  # Project configuration
  region = "europe-central2"
  
  # Backend configuration for remote state
  net_svcp_backend_bucket = "tfstate-bucket"
  net_svcp_backend_prefix = "net-svcp"
  svc_projects_backend_bucket = "tfstate-bucket"
  svc_projects_backend_prefix = "svc-projects"
}
```

### Advanced Configuration

```hcl
module "iam" {
  source = "./net-iam"

  # GKE Workload Identity Configuration
  gke_workload_identity_service_accounts = {
    "api-service" = {
      display_name               = "API Service Account"
      description                = "Service account for API workloads"
      kubernetes_namespace       = "api"
      kubernetes_service_account = "api-sa"
      gcp_roles = [
        "roles/storage.objectViewer",
        "roles/cloudsql.client"
      ]
    }
    
    "backend-service" = {
      display_name               = "Backend Service Account"
      description                = "Service account for backend workloads"
      kubernetes_namespace       = "backend"
      kubernetes_service_account = "backend-sa"
      gcp_roles = [
        "roles/cloudsql.client",
        "roles/redis.client"
      ]
    }
  }

  # OS Login Users
  os_login_users = [
    "user:admin@example.com",
    "user:devops@example.com"
  ]

  # IAP Tunnel Users
  iap_tunnel_users = [
    "user:admin@example.com",
    "user:devops@example.com"
  ]

  # Bastion Service Account Configuration
  bastion_service_account_config = {
    account_id   = "bastion-prod-host"
    display_name = "Bastion Admin Service Account"
    description  = "Service account for bastion host with admin access"
    gcp_roles = [
      "roles/container.admin",
      "roles/cloudsql.admin",
      "roles/storage.admin",
      "roles/compute.loadBalancerAdmin"
    ]
  }
}
```

## Configuration Variables

### Core Configuration

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|:--------:|
| `region` | GCP region for resources | `string` | `"europe-central2"` | no |
| `net_svcp_backend_bucket` | Backend bucket for net-svcp state | `string` | `"tfstate"` | no |
| `net_svcp_backend_prefix` | Backend prefix for net-svcp state | `string` | `"net-svcp"` | no |
| `svc_projects_backend_bucket` | Backend bucket for svc-projects state | `string` | `"tfstate"` | no |
| `svc_projects_backend_prefix` | Backend prefix for svc-projects state | `string` | `"svc-projects"` | no |

### GKE IAM Configuration

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|:--------:|
| `enable_gke_iam` | Enable GKE IAM resources | `bool` | `true` | no |
| `gke_workload_identity_service_accounts` | Workload identity service accounts | `map(object)` | `{}` | no |
| `gke_service_account_config` | GKE service account configuration | `object` | See below | no |

**Default GKE Service Account Roles:**

- `roles/container.nodeServiceAccount`
- `roles/container.serviceAgent`
- `roles/container.developer`
- `roles/logging.logWriter`
- `roles/monitoring.metricWriter`
- `roles/monitoring.viewer`
- `roles/stackdriver.resourceMetadata.writer`

### Cloud SQL IAM Configuration

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|:--------:|
| `enable_sql_iam` | Enable Cloud SQL IAM resources | `bool` | `true` | no |

### OS Login Configuration

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|:--------:|
| `enable_os_login_iam` | Enable OS Login IAM resources | `bool` | `false` | no |
| `os_login_users` | List of IAM users for OS Login | `list(string)` | `[]` | no |

### Bastion IAM Configuration

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|:--------:|
| `enable_bastion_iam` | Enable Bastion IAM resources | `bool` | `false` | no |
| `bastion_service_account_config` | Bastion service account configuration | `object` | See below | no |
| `existing_bastion_service_account` | Existing bastion service account email | `string` | `"bastion-prod-host@host-project.iam.gserviceaccount.com"` | no |

**Default Bastion Service Account Roles:**

- `roles/container.admin`
- `roles/container.clusterAdmin`
- `roles/container.developer`
- `roles/cloudsql.admin`
- `roles/cloudsql.client`
- `roles/cloudsql.instanceUser`
- `roles/storage.admin`
- `roles/storage.objectAdmin`
- `roles/redis.admin`
- `roles/redis.editor`
- `roles/compute.loadBalancerAdmin`
- `roles/compute.networkAdmin`
- `roles/compute.securityAdmin`
- `roles/compute.instanceAdmin`
- `roles/iam.serviceAccountUser`
- `roles/logging.logWriter`
- `roles/monitoring.metricWriter`
- `roles/monitoring.viewer`

### IAP Tunnel Configuration

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|:--------:|
| `enable_iap_tunnel_iam` | Enable IAP Tunnel IAM resources | `bool` | `false` | no |
| `iap_tunnel_users` | List of IAM users for IAP Tunnel | `list(string)` | `[]` | no |

## Outputs

| Output | Description |
|--------|-------------|
| `gke_workload_identity_service_accounts` | Map of GKE workload identity service account emails |
| `cloudsql_admin_service_account_email` | Cloud SQL admin service account email |
| `cloudsql_admin_service_account_name` | Cloud SQL admin service account name |
| `cloudsql_admin_service_account_id` | Cloud SQL admin service account ID |
| `gke_service_account_email` | GKE service account email |
| `gke_service_account_name` | GKE service account name |
| `gke_service_account_id` | GKE service account ID |
| `iap_tunnel_users` | List of users with IAP Tunnel access |

## Dependencies

This module depends on the following Terraform configurations:

1. **net-svpc** - Provides shared VPC network information
2. **svc-projects** - Provides project IDs and service account details

## Security Considerations

### Principle of Least Privilege

- Each service account is granted only the minimum required permissions
- Workload identity service accounts have project-specific access
- Bastion service account has comprehensive access for administrative tasks

### Access Control

- OS Login and IAP Tunnel access is restricted to authorized users only
- All access is logged and monitored
- Service accounts use workload identity for enhanced security

### Compliance

- IAM policies follow Google Cloud security best practices
- Access is auditable and traceable
- Service accounts are properly labeled and documented

## Troubleshooting

### Common Issues

1. **Permission Denied Errors**
   - Verify that the service account has the required roles
   - Check that the project IDs are correct
   - Ensure APIs are enabled in the target projects

2. **Workload Identity Issues**
   - Verify Kubernetes service account exists in the specified namespace
   - Check that the GKE cluster has workload identity enabled
   - Ensure the service account has the correct IAM bindings

3. **OS Login/IAP Access Issues**
   - Verify user email addresses are correct
   - Check that users have the required IAM roles
   - Ensure the compute instances have the correct metadata

### Debugging Commands

```bash
# Check service account permissions
gcloud projects get-iam-policy PROJECT_ID --flatten="bindings[].members" --format="table(bindings.role)" --filter="bindings.members:serviceAccount:ACCOUNT_EMAIL"

# Verify workload identity binding
gcloud iam service-accounts get-iam-policy SERVICE_ACCOUNT_EMAIL

# Check OS Login status
gcloud compute os-login describe-profile --user=USER_EMAIL
```

## Related Documentation

- [Google Cloud IAM Documentation](https://cloud.google.com/iam/docs)
- [GKE Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
- [Cloud SQL IAM](https://cloud.google.com/sql/docs/mysql/iam)
- [OS Login](https://cloud.google.com/compute/docs/oslogin)
- [Identity-Aware Proxy](https://cloud.google.com/iap/docs) 
