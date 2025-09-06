# GKE RBAC Configuration

This directory contains the RBAC (Role-Based Access Control) configuration for the fintech production GKE cluster.

## Structure

```
rbac/
├── iam-roles/                    # Google Cloud IAM roles and Kubernetes ClusterRoles
│   ├── submodules/
│   │   ├── google-prod/         # Google Cloud IAM bindings
│   │   └── kubernetes-prod/     # Kubernetes ClusterRoles
│   └── main.tf
└── iam-bindings/                # Kubernetes RoleBindings and ClusterRoleBindings
    ├── submodules/
    │   └── kubernetes-prod-binding/  # Kubernetes RoleBindings
    └── main.tf
```

## Integration with GKE Configuration

The RBAC configuration is properly integrated with the main GKE cluster configuration:

### 1. Security Group Configuration

- **GKE Cluster**: Uses `authenticator_groups_config` with security group `gke-security-groups@fintech.com`
- **RBAC**: Creates namespace `gke-security-groups` and assigns group-based permissions

### 2. Provider Configuration

- **Google Provider**: Configured for `us-central1` region
- **Kubernetes Provider**: Configured with proper aliases for different environments
- **Backend**: Uses GCS backend with proper state management

### 3. Group-Based Access Control

The configuration implements a comprehensive RBAC strategy:

#### Google Cloud IAM Roles

- **Container Viewer**: `fintech-devops@fintech.com`
- **Container Developer**: `fintech-backend@fintech.com`, `fintech-frontend@fintech.com`, `fintech-mobile@fintech.com`
- **Monitoring Viewer**: `fintech-devops@fintech.com`, `fintech-qa@fintech.com`
- **Logging Viewer**: `fintech-devops@fintech.com`, `fintech-qa@fintech.com`

#### Kubernetes ClusterRoles

- **custom:secrets-admin**: Full access to secrets
- **custom:pod-manager**: Manage pods, logs, and exec access
- **custom:deployment-manager**: Manage deployments and replicasets
- **custom:service-manager**: Manage services, endpoints, and ingresses
- **custom:configmap-manager**: Manage configmaps
- **custom:monitoring-viewer**: Read-only access to monitoring resources

#### Namespace-Specific RoleBindings

- **Backend Team**: Pod management in `backend`, `api`, `workers` namespaces
- **Frontend Team**: Pod management in `frontend` namespace
- **Mobile Team**: Pod management in `mobile` namespace
- **DevOps Team**: Full management across all namespaces
- **QA Team**: Monitoring access cluster-wide

## Validation Status

✅ **Configuration Validated**: Both `iam-roles` and `iam-bindings` configurations pass Terraform validation

✅ **Provider Integration**: Google and Kubernetes providers properly configured

✅ **Backend Configuration**: GCS backend properly configured for state management

✅ **Group Names**: Fixed typo in group names (changed from "technolgy" to "technology")

✅ **Module Structure**: Proper module organization with required_providers configuration

✅ **Security Integration**: RBAC configuration aligns with GKE security group configuration

## Deployment Order

1. **Deploy GKE Cluster**: Ensure the main GKE cluster is deployed first
2. **Deploy IAM Roles**: Apply `iam-roles` configuration to create Google Cloud IAM bindings and Kubernetes ClusterRoles
3. **Deploy IAM Bindings**: Apply `iam-bindings` configuration to create Kubernetes RoleBindings

## Security Considerations

- All roles follow the principle of least privilege
- Team-specific access is scoped to relevant namespaces
- DevOps team has broader access for operational needs
- QA team has read-only monitoring access
- Secrets management is restricted to DevOps team only

## Namespaces Covered

- `backend`
- `frontend`
- `mobile`
- `api`
- `workers`
- `monitoring`
- `gke-security-groups` (system namespace for RBAC)

## Commands

```bash
# Deploy IAM Roles
cd svc-gke/rbac/iam-roles
terraform init
terraform plan
terraform apply

# Deploy IAM Bindings
cd svc-gke/rbac/iam-bindings
terraform init
terraform plan
terraform apply
```

## Notes

- The configuration assumes the existence of Google Workspace groups with the specified email addresses
- The GKE cluster must be configured with the security group `gke-security-groups@fintech.com`
- All resources are tagged with appropriate labels for cost tracking and management
