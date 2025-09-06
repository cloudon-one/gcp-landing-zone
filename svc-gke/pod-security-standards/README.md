# Pod Security Standards Module

This module configures Kubernetes Pod Security Standards for the GKE cluster using local kubeconfig for private endpoint access.

## Prerequisites

1. **GKE cluster must be deployed first** (from parent svc-gke module)
2. **Cluster credentials configured locally**:

   ```bash
   gcloud container clusters get-credentials gke-cluster \
     --region=us-central1 \
     --project=gke-project
   ```

3. **Network access to private endpoint** (via bastion, VPN, or authorized network)

## Configuration

### Authentication Method

- **Uses local kubeconfig** (`~/.kube/config` by default)
- **Private endpoint compatible** - leverages existing cluster credentials
- **No manual certificate/token management** required

### Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `region` | GCP region where GKE cluster is located | Required |
| `project_id` | GCP project ID containing the GKE cluster | Required |
| `cluster_name` | Name of the GKE cluster | Required |
| `kubeconfig_path` | Path to kubeconfig file | `~/.kube/config` |
| `pod_security_standards_config` | PSS configuration (mode, version) | `{mode="ENFORCED", version="v1.32"}` |

### Configuration Files

- **terraform.tfvars**: Contains cluster-specific values
- **kubeconfig**: Standard Kubernetes configuration file

## Deployed Resources

### Namespace Security Labels

Uses `kubernetes_labels` resource to apply Pod Security Standards to existing namespaces:

- **kube-system**: `restricted` enforcement (system workloads)
- **default**: `baseline` enforcement, `restricted` audit/warn (user workloads)
- **monitoring**: `restricted` enforcement (monitoring stack)
- **ingress-nginx**: Created with `baseline` enforcement (ingress controller)

### RBAC Resources

- **ClusterRole**: `pod-security-standards-viewer` for PSS resource access
- **ClusterRoleBinding**: Grants access to default service account

### Monitoring Resources

- **ConfigMap**: Enhanced Prometheus alert rules with cluster/project context
  - Includes cluster name and project ID in alerts
  - Provides runbook URL for remediation guidance

## Deployment Steps

1. **Ensure cluster access**:

   ```bash
   kubectl get nodes
   ```

2. **Deploy Pod Security Standards**:

   ```bash
   cd pod-security-standards
   terraform init
   terraform plan
   terraform apply
   ```

3. **Verify deployment**:

   ```bash
   kubectl get namespaces --show-labels
   kubectl get clusterrole pod-security-standards-viewer
   ```

## Network Access Requirements

For private GKE clusters, ensure one of:

1. **Bastion host** in same VPC with cluster access
2. **Cloud Shell** or compute instance in authorized networks
3. **VPN connection** to cluster's private network
4. **Identity-Aware Proxy** for secure access

## Namespace Management

### Existing Namespaces

- **kube-system**, **default**, **monitoring**: Use `kubernetes_labels` to manage existing namespaces
- **Does not recreate** existing namespaces, only applies security labels

### New Namespaces  

- **ingress-nginx**: Created if it doesn't exist
- **Future namespaces**: Add similar `kubernetes_labels` resources

## Security Levels

### Baseline

- Minimal restrictions
- Applied to: `default`, `ingress-nginx` namespaces
- Allows most common workloads while preventing known privilege escalations

### Restricted

- Maximum restrictions
- Applied to: `kube-system`, `monitoring` namespaces
- Enforces the most secure pod configuration

## Troubleshooting

### Common Issues

**Connection timeouts**:

```bash
kubectl cluster-info

gcloud container clusters describe gke-cluster \
  --region=us-central1 --format="get(masterAuthorizedNetworksConfig)"
```

**Namespace already exists errors**:

- Fixed by using `kubernetes_labels` instead of `kubernetes_namespace`
- Manages labels on existing namespaces without recreation

**Authentication errors**:

```bash
gcloud container clusters get-credentials gke-cluster \
  --region=us-central1 \
  --project=gke-project

kubectl auth can-i get pods --all-namespaces
```

### Validation Commands

```bash
kubectl get namespace kube-system -o yaml | grep pod-security
kubectl get events --field-selector reason=FailedCreate
kubectl run test-pod --image=nginx --dry-run=server
kubectl get namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.labels.pod-security\.kubernetes\.io/enforce}{"\n"}{end}'
```

## Network Policies

**Important**: This module does NOT manage network policies. All network policies (including DNS, egress, and critical service rules) are managed in the `/network-policies` directory to avoid conflicts.

When adding new namespaces with PSS, ensure you also update the network policies in `/network-policies/modules/default-deny/main.tf`.

## Outputs

| Output | Description |
|--------|-------------|
| `pod_security_standards_enabled` | Whether PSS are enabled |
| `pod_security_standards_mode` | Current PSS mode |
| `pod_security_standards_version` | PSS version |
| `namespaces_with_psa` | Map of namespaces with PSS applied |

## Security Considerations

1. **Gradual Rollout**: Start with `BASELINE` mode and gradually move to `RESTRICTED`
2. **Testing**: Test workloads in a staging environment before applying to production
3. **Monitoring**: Monitor for PSS violations and adjust policies as needed
4. **Network Policies**: Ensure network policies are compatible with PSS restrictions