# Production GKE Cluster Config

This service deploys a production-ready Google Kubernetes Engine (GKE) cluster with enterprise-grade security, monitoring, and operational features for the fintech platform.

## 🏗️ Architecture Overview

### Cluster Configuration

- **Cluster Name**: `gke-cluster`
- **Project**: `gke-project`
- **Region**: `us-central1`
- **Release Channel**: `STABLE`
- **Network**: Private GKE VPC (10.160.0.0/16)
- **Master CIDR**: 10.160.1.0/28
- **Pod Range**: 10.160.128.0/17
- **Service Range**: 10.160.8.0/22

### Node Pools

1. **app-pool**: Application workloads (3-9 nodes, n2d-standard-4)
2. **service-pool**: Service workloads (2-6 nodes, n2d-standard-4)

### Directory Structure

```
gke/
├── main.tf                    # Main GKE cluster configuration
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── terraform.tfvars           # Variable values
├── README.md                  # This documentation
├── network-policies/          # Network security policies
│   ├── main.tf               # Network policy configuration
│   ├── modules/              # Policy modules by namespace
│   ├── DEPLOYMENT_GUIDE.md   # Deployment instructions
│   └── README.md             # Network policy documentation
├── pod-security-standards/   # Pod Security Standards
│   ├── main.tf               # PSS configuration
│   ├── variables.tf          # PSS variables
│   └── README.md             # PSS documentation
├── performance-management/   # Performance and resource management
│   ├── main.tf               # Resource quotas, HPA, PDB
│   ├── load-testing.tf       # Load testing infrastructure
│   ├── performance-test.sh   # Performance testing script
│   └── README.md             # Performance management guide
└── rbac/                     # Role-Based Access Control
    ├── iam-roles/            # Google Cloud IAM and Kubernetes ClusterRoles
    ├── iam-bindings/         # Kubernetes RoleBindings
    └── README.md             # RBAC documentation
```

## 🔐 Security Features

### 🔒 Private Cluster Configuration

```hcl
# Private nodes and endpoints
enable_private_nodes    = true
enable_private_endpoint = true

# Master authorized networks
master_authorized_networks = [
  {
    cidr_block   = "10.160.0.0/16"  # GKE VPC
    display_name = "gke-vpc"
  },
  {
    cidr_block   = "10.161.0.0/16"  # Data VPC
    display_name = "data-vpc"
  }
]
```

### 🛡️ Node Security

```hcl
# Shielded nodes with secure boot and integrity monitoring
shielded_instance_config = {
  enable_integrity_monitoring = true
  enable_secure_boot          = true
}

# Confidential computing for sensitive workloads
confidential_nodes = {
  enabled = true
}

# Disable insecure kubelet read-only port
insecure_kubelet_readonly_port_enabled = "FALSE"
```

### 🔑 Workload Identity

```hcl
# Enable Workload Identity for secure pod-to-GCP authentication
enable_workload_identity = true

# Workload pool configuration
workload_pool = "gke-project.svc.id.goog"
```

### 🗝️ Database Encryption

```hcl
# Encrypt etcd data with customer-managed keys
database_encryption = {
  state    = "ENCRYPTED"
  key_name = "projects/gke-project/locations/us-central1/keyRings/gke-kms/cryptoKeys/gke-kms"
}
```

### 🛡️ Pod Security Standards

```hcl
# Enforce Pod Security Standards
pod_security_standards = {
  mode    = "ENFORCED"
  version = "v1.32"
}
```

**Note**: Pod Security Standards are applied via a separate module in the `pod-security-standards/` directory. This module uses `kubernetes_labels` to configure existing namespaces and requires cluster credentials for deployment.

## 🌐 Network Security

### Network Policies

The `network-policies/` directory implements comprehensive network security using a zero-trust model:

#### Architecture

- **Default Deny**: All traffic is denied by default
- **Namespace Isolation**: Each namespace has specific ingress/egress rules
- **DNS Resolution**: Maintained for all namespaces
- **Managed Services**: IP-based access to Cloud SQL and Memorystore

#### Namespace Structure

- **backend**: Backend services and business logic
- **frontend**: Frontend applications and user interfaces  
- **api**: API services and external interfaces
- **workers**: Background job processors
- **mobile**: Mobile application services
- **monitoring**: Observability and monitoring tools

#### Key Features

- Zero-trust security model
- Pod-to-pod communication control
- Database access restrictions
- Monitoring and observability support

### Advanced Datapath

```hcl
# Enable advanced datapath for better performance
datapath_provider = "ADVANCED_DATAPATH"
```

### Network Policy

```hcl
# Legacy network policy disabled (using Advanced Datapath/Cilium)
enable_network_policy = false
```

**Note**: Network policies are managed separately in the `network-policies/` directory using Cilium's advanced features via Advanced Datapath.

## 🔐 Pod Security Standards

The `pod-security-standards/` directory configures Kubernetes Pod Security Standards for enhanced workload security:

### Security Levels

#### Baseline

- **Applied to**: `default`, `ingress-nginx` namespaces
- **Restrictions**: Minimal restrictions, prevents known privilege escalations
- **Use Case**: User workloads and ingress controllers

#### Restricted

- **Applied to**: `kube-system`, `monitoring` namespaces  
- **Restrictions**: Maximum restrictions, most secure pod configuration
- **Use Case**: System workloads and monitoring stack

### Implementation

- Uses `kubernetes_labels` to manage existing namespaces
- Private endpoint compatible with local kubeconfig
- No manual certificate/token management required
- Integrates with network policies for comprehensive security

## 📊 Performance Management

The `performance-management/` directory provides comprehensive resource management and performance optimization:

### Resource Management

#### Resource Quotas

- **Production Namespace**: CPU, memory, and storage limits
- **Monitoring Namespace**: Dedicated resource allocation
- **Load Testing Namespace**: Isolated testing environment

#### Limit Ranges

- **Default Limits**: CPU and memory limits for all pods
- **Request Limits**: Minimum resource requirements
- **Storage Limits**: Persistent volume claim limits

#### Priority Classes

- **system-cluster-critical**: System components
- **system-node-critical**: Node-level components
- **high-priority**: Application workloads
- **default-priority**: Standard workloads

### Autoscaling

#### Horizontal Pod Autoscaling (HPA)

- **Application HPA**: CPU and memory-based scaling
- **API HPA**: Request-based scaling
- **Custom Metrics**: Integration with Prometheus metrics

#### Pod Disruption Budgets (PDB)

- **Application PDB**: Ensures availability during updates
- **API PDB**: Maintains API service availability
- **Database PDB**: Protects database workloads

### Load Testing

#### Infrastructure

- **Apache Bench**: HTTP load testing
- **Custom Scripts**: Burst and peak load testing
- **Monitoring**: Real-time performance metrics

#### Testing Scenarios

- **Burst Testing**: Sudden traffic spikes
- **Peak Testing**: Sustained high load
- **Stress Testing**: Resource exhaustion scenarios

## 👥 Role-Based Access Control (RBAC)

The `rbac/` directory implements comprehensive access control for the GKE cluster:

### Google Cloud IAM Integration

#### IAM Roles

- **Container Viewer**: `devops@example.com`
- **Container Developer**: Backend, frontend, and mobile teams
- **Monitoring Viewer**: DevOps and QA teams
- **Logging Viewer**: DevOps and QA teams

#### Security Groups

- **GKE Security Group**: `gke-groups@example.com`
- **Group-Based Access**: Integrated with Kubernetes RBAC

### Kubernetes RBAC

#### ClusterRoles

- **custom:secrets-admin**: Full access to secrets
- **custom:pod-manager**: Manage pods, logs, and exec access
- **custom:deployment-manager**: Manage deployments and replicasets
- **custom:service-manager**: Manage services, endpoints, and ingresses
- **custom:configmap-manager**: Manage configmaps
- **custom:monitoring-viewer**: Read-only access to monitoring resources

#### Namespace-Specific Access

- **Backend Team**: Pod management in `backend`, `api`, `workers` namespaces
- **Frontend Team**: Pod management in `frontend` namespace
- **Mobile Team**: Pod management in `mobile` namespace
- **DevOps Team**: Full management across all namespaces
- **QA Team**: Monitoring access cluster-wide

## 🔧 Workload Identity Implementation

### Service Account Configuration

```hcl
# GKE service account with minimal required permissions
service_account = "gke-service-account@gke-project.iam.gserviceaccount.com"

# OAuth scopes for the service account
oauth_scopes = [
  "https://www.googleapis.com/auth/userinfo.email",
  "https://www.googleapis.com/auth/cloud-platform"
]
```

### Kubernetes Annotations for Workload Identity

#### For Deployments

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
  namespace: production
spec:
  template:
    metadata:
      annotations:
        iam.gke.io/gcp-service-account: app-sa@gke-project.iam.gserviceaccount.com
    spec:
      serviceAccountName: app-sa
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
  namespace: production
  annotations:
    iam.gke.io/gcp-service-account: app-sa@gke-project.iam.gserviceaccount.com
```

#### For Jobs and CronJobs

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: data-processing-job
spec:
  template:
    metadata:
      annotations:
        iam.gke.io/gcp-service-account: data-processor@gke-project.iam.gserviceaccount.com
    spec:
      serviceAccountName: data-processor-sa
      restartPolicy: Never
      containers:
      - name: data-processor
        image: gcr.io/gke-project/data-processor:latest
```

### IAM Role Binding

```bash
# Bind IAM roles to the GCP service account
gcloud projects add-iam-policy-binding gke-project \
  --member="serviceAccount:fintech-app-sa@gke-project.iam.gserviceaccount.com" \
  --role="roles/storage.objectViewer"

# For Cloud SQL access
gcloud projects add-iam-policy-binding gke-project \
  --member="serviceAccount:app-sa@gke-project.iam.gserviceaccount.com" \
  --role="roles/cloudsql.client"
```

## 📊 Monitoring and Observability

### Managed Prometheus

```hcl
# Enable managed Prometheus for advanced monitoring
monitoring = {
  enable_components         = ["SYSTEM_COMPONENTS", "STORAGE", "POD", "DEPLOYMENT", "STATEFULSET", "DAEMONSET", "HPA", "JOBSET", "CADVISOR", "KUBELET", "APISERVER", "SCHEDULER", "CONTROLLER_MANAGER"]
  enable_managed_prometheus = true
}
```

### Comprehensive Logging

```hcl
# Enable all logging components
logging = {
  enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS", "APISERVER", "SCHEDULER", "CONTROLLER_MANAGER"]
}
```

### Security Posture Monitoring

```hcl
# Enable security posture management
security_posture_config = {
  mode               = "BASIC"
  vulnerability_mode = "VULNERABILITY_BASIC"
}
```

## 🔄 Auto-scaling Configuration

### Cluster Auto-scaling

```hcl
cluster_autoscaling = {
  enabled             = true
  autoscaling_profile = "BALANCED"
  
  # Resource limits for auto-provisioned node pools
  resource_limits = [
    {
      resource_type = "cpu"
      minimum       = 8
      maximum       = 16
    },
    {
      resource_type = "memory"
      minimum       = 16
      maximum       = 128
    }
  ]
}
```

### Node Pool Auto-scaling

```hcl
# App pool: 3-9 nodes
app = {
  autoscaling = {
    min_node_count  = 3
    max_node_count  = 9
    location_policy = "BALANCED"
  }
}

# Service pool: 2-6 nodes
service = {
  autoscaling = {
    min_node_count  = 2
    max_node_count  = 6
    location_policy = "BALANCED"
  }
}
```

### Vertical Pod Auto-scaling

```hcl
# Enable VPA for automatic resource optimization
vertical_pod_autoscaling = {
  enabled = true
}
```

## 🛠️ Maintenance and Operations

### Maintenance Windows

```hcl
# Weekend maintenance window
maintenance_window = {
  recurring_window = {
    start_time = "2025-08-19T23:00:00Z"
    end_time   = "2025-08-20T23:00:00Z"
    recurrence = "FREQ=WEEKLY;BYDAY=SA,SU"
  }
}
```

### Node Management

```hcl
# Auto-repair and auto-upgrade
management = {
  auto_repair  = true
  auto_upgrade = true
}

# Rolling upgrade strategy
upgrade_settings = {
  max_surge       = 1
  max_unavailable = 0
  strategy        = "SURGE"
}
```

## 🔌 Network Configuration

### DNS Configuration

```hcl
dns_config = {
  cluster_dns_domain = "cluster.local"
}
```

## 📦 Add-ons and Extensions

### CSI Drivers

```hcl
addons_config = {
  # Persistent disk CSI driver
  gce_persistent_disk_csi_driver_config = {
    enabled = true
  }
  
  # Filestore CSI driver
  gcp_filestore_csi_driver_config = {
    enabled = true
  }
  
  # GCS FUSE CSI driver
  gcs_fuse_csi_driver_config = {
    enabled = true
  }
}
```

### Backup and Recovery

```hcl
# GKE backup agent
gke_backup_agent_config = {
  enabled = true
}
```

### Ray Operator

```hcl
# Ray operator for distributed computing
ray_operator_config = {
  enabled = true
  ray_cluster_logging_config = {
    enabled = true
  }
  ray_cluster_monitoring_config = {
    enabled = true
  }
}
```

## 🏷️ Resource Management

### Labels and Tags

```hcl
# Common labels for all resources
common_labels = {
  environment     = "production"
  project         = "prod"
  managed_by      = "terraform"
  deployment_date = formatdate("YYYY-MM-DD", timestamp())
  component       = "gke"
}

# Node pool specific labels
labels = {
  node-pool   = "app"
  environment = "production"
}
```

### Resource Limits

```hcl
# Node pool resource limits
workload_config = {
  resource_limits = {
    cpu    = "2"
    memory = "8Gi"
  }
  resource_requests = {
    cpu    = "1"
    memory = "4Gi"
  }
}
```

## 🚀 Deployment Sequence

### Prerequisites

1. **Network Infrastructure**: `net-svcp` must be deployed
2. **IAM Configuration**: `net-iam` must be deployed
3. **Projects**: `svc-projects` must be deployed

### Step 1: Deploy Main GKE Cluster

```bash
cd gke
terraform init
terraform plan
terraform apply
```

### Step 2: Deploy Network Policies

```bash
cd gke/network-policies
terraform init
terraform plan
terraform apply
kubectl get networkpolicies --all-namespaces
```

### Step 3: Deploy Pod Security Standards

```bash
gcloud container clusters get-credentials gke-cluster \
  --region=us-central1 \
  --project=gke-project

cd gke/pod-security-standards
terraform init
terraform plan
terraform apply
kubectl get namespaces --show-labels
```

### Step 4: Deploy RBAC Configuration

```bash
cd gke/rbac/iam-roles
terraform init
terraform plan
terraform apply

cd gke/rbac/iam-bindings
terraform init
terraform plan
terraform apply
```

### Step 5: Deploy Performance Management

```bash
cd gke/performance-management
terraform init
terraform plan
terraform apply
./performance-test.sh
```

### Verification

```bash
kubectl cluster-info
kubectl get nodes
kubectl get pods --all-namespaces
kubectl get networkpolicies --all-namespaces
kubectl get namespaces --show-labels
kubectl get namespace kube-system -o yaml | grep pod-security
kubectl get clusterroles | grep custom
kubectl get clusterrolebindings | grep custom
kubectl get resourcequota --all-namespaces
kubectl get hpa --all-namespaces
kubectl get pdb --all-namespaces
```

## 🔍 Best Practices Implementation

### 1. Security Best Practices

- ✅ Private cluster with no public endpoints
- ✅ Workload Identity for secure authentication
- ✅ Shielded nodes with secure boot
- ✅ Confidential computing support
- ✅ Customer-managed encryption keys
- ✅ Pod Security Standards enforcement
- ✅ Network policies with zero-trust model
- ✅ Comprehensive RBAC implementation
- ✅ Disabled insecure kubelet ports

### 2. Operational Best Practices

- ✅ Stable release channel for reliability
- ✅ Comprehensive monitoring and logging
- ✅ Automated maintenance windows
- ✅ Rolling upgrade strategy
- ✅ Auto-repair and auto-upgrade
- ✅ Deletion protection enabled
- ✅ Resource quotas and limits
- ✅ Performance management and testing

### 3. Performance Best Practices

- ✅ Advanced datapath for better networking
- ✅ Vertical Pod Auto-scaling
- ✅ Cluster auto-scaling with resource limits
- ✅ Balanced autoscaling profile
- ✅ Optimized node pool configurations
- ✅ Load testing infrastructure
- ✅ Performance monitoring and alerting

### 4. Cost Optimization

- ✅ Resource limits and requests
- ✅ Auto-scaling with appropriate min/max values
- ✅ Balanced disk types (pd-balanced)
- ✅ Cost management configuration enabled
- ✅ Resource quotas to prevent over-allocation

## 🔧 Usage Examples

### Deploying Applications with Workload Identity

```yaml
gcloud iam service-accounts create my-app \
  --display-name="Application Service Account"

gcloud projects add-iam-policy-binding gke-project \
  --member="serviceAccount:my-app@gke-project.iam.gserviceaccount.com" \
  --role="roles/storage.objectViewer"

kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app-sa
  namespace: production
  annotations:
    iam.gke.io/gcp-service-account: my-app@gke-project.iam.gserviceaccount.com
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
      annotations:
        iam.gke.io/gcp-service-account: my-app@gke-project.iam.gserviceaccount.com
    spec:
      serviceAccountName: my-app-sa
      containers:
      - name: my-app
        image: gcr.io/gke-project/my-app:latest
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
EOF
```

### Testing Network Policies

```bash
kubectl exec -it frontend-test -n frontend -- wget -q --timeout=5 backend-service.backend.svc.cluster.local:8080
kubectl exec -it backend-test -n backend -- wget -q --timeout=5 api-service.api.svc.cluster.local:8080
kubectl exec -it frontend-test -n frontend -- wget -q --timeout=5 prometheus-service.monitoring.svc.cluster.local:9090
```

### Monitoring Application Metrics

```bash
gcloud container clusters describe gke-cluster \
  --region us-central1 \
  --project gke-project \
  --format="value(masterAuth.clusterCaCertificate)" | base64 -d > cluster-ca.pem

gcloud monitoring metrics list --filter="metric.type:kubernetes"
```

## 🚨 Troubleshooting

### Common Issues

1. **Workload Identity Not Working**

   ```bash
   # Verify service account binding
   kubectl get serviceaccount my-app-sa -n production -o yaml
   
   # Check IAM policy
   gcloud projects get-iam-policy gke-project \
     --flatten="bindings[].members" \
     --format="table(bindings.role)" \
     --filter="bindings.members:my-app@gke-project.iam.gserviceaccount.com"
   ```

2. **Network Policy Issues**

   ```bash
   # Check network policies
   kubectl get networkpolicies --all-namespaces
   kubectl describe networkpolicies -n <namespace>
   
   # Test connectivity
   kubectl exec -it <pod-name> -n <namespace> -- nc -zv <target-service> <port>
   
   # Check Cilium network policies (Advanced Datapath)
   kubectl get ciliumnetworkpolicies --all-namespaces
   ```

3. **Pod Security Standards Issues**

   ```bash
   # Check PSS labels on namespaces
   kubectl get namespaces --show-labels | grep pod-security
   
   # View PSS violations
   kubectl get events --field-selector reason=FailedCreate --sort-by='.lastTimestamp'
   
   # Test pod security enforcement
   kubectl run test-pod --image=nginx --dry-run=server
   ```

4. **RBAC Issues**

   ```bash
   # Check cluster roles
   kubectl get clusterroles | grep custom
   kubectl describe clusterrole custom:pod-manager
   
   # Check role bindings
   kubectl get clusterrolebindings | grep custom
   kubectl get rolebindings --all-namespaces
   
   # Test permissions
   kubectl auth can-i get pods --all-namespaces
   kubectl auth can-i create deployments --namespace=backend
   ```

5. **Performance Management Issues**

   ```bash
   # Check resource quotas
   kubectl describe resourcequota --all-namespaces
   
   # Check HPA status
   kubectl describe hpa -n production
   kubectl get apiservice v1beta1.metrics.k8s.io
   
   # Check pod disruption budgets
   kubectl get pdb --all-namespaces
   kubectl describe pdb app-pdb -n production
   ```

6. **Node Pool Scaling Issues**

   ```bash
   # Check cluster autoscaler status
   kubectl get pods -n kube-system | grep cluster-autoscaler
   
   # View autoscaler logs
   kubectl logs -n kube-system deployment/cluster-autoscaler
   ```

7. **Private Endpoint Access Issues**

   ```bash
   # Verify cluster endpoint connectivity
   kubectl cluster-info
   
   # Check authorized networks
   gcloud container clusters describe gke-cluster \
     --region=us-central1 --format="get(masterAuthorizedNetworksConfig)"
   
   # Refresh cluster credentials
   gcloud container clusters get-credentials gke-cluster \
     --region=us-central1 \
     --project=gke-project
   ```

## 📞 Support

For issues and questions:

- Check the [GKE documentation](https://cloud.google.com/kubernetes-engine/docs)
- Review [Workload Identity best practices](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
- Review [Network Policy documentation](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy)
- Review [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- Contact the DevOps team
- Create an issue in this repository

---

**Cluster Type**: Private GKE with Workload Identity  
**Security Level**: Enterprise-grade with confidential computing  
**Monitoring**: Comprehensive with managed Prometheus  
**Network Security**: Zero-trust with network policies  
**Access Control**: Comprehensive RBAC implementation  
**Performance**: Optimized with resource management  
**Last Updated**: September 2025  
**Terraform Version**: >= 1.5.0 
