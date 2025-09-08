# GCP Landing Zone Template

A comprehensive, enterprise-grade Google Cloud Platform (GCP) landing zone designed for fintech organizations, providing secure, scalable, and compliant cloud infrastructure with strong network isolation, identity management, and regulatory compliance features.

## 🏗️ Architecture Overview

This landing zone implements a multi-layered security architecture with:

- **Network Infrastructure**: Secure VPC design with shared VPC, private subnets, and controlled connectivity
- **Identity & Access Management**: Fine-grained IAM policies and service accounts
- **Compute Resources**: Auto-scaling GKE clusters with security hardening
- **Data Services**: Encrypted Cloud SQL and Redis instances
- **Security Controls**: VPC Service Controls, bastion hosts, and comprehensive monitoring
- **Compliance**: Built-in controls for financial services regulations

### 🎯 Key Features

- ✅ **Multi-environment support** (dev, staging, prod)
- ✅ **Zero-trust network architecture** with VPC Service Controls
- ✅ **Private GKE clusters** with authorized networks
- ✅ **Encrypted data at rest and in transit**
- ✅ **Centralized logging and monitoring**
- ✅ **Automated security scanning** and compliance checks
- ✅ **Infrastructure as Code** with Terraform
- ✅ **Disaster recovery** and backup strategies

## 📁 Project Structure

```
gcp-landing-zone/
├── bastion/          # Secure bastion host for administration
├── iam/             # Identity and Access Management policies
├── shared-vpc/            # Shared VPC network infrastructure
├── vpcsc/           # VPC Service Controls perimeter
├── gke/             # Google Kubernetes Engine clusters
├── projects/        # GCP project structure and organization
├── redis/           # Redis instances for caching
├── sql/             # Cloud SQL databases
├── locals.tf            # Local variable definitions
├── README.md            # This file
├── CONTRIBUTING.md      # Contribution guidelines
└── SECURITY.md          # Security policies and procedures
```

## 🚀 Quick Start

### Prerequisites

- Google Cloud account with billing enabled
- Terraform >= 1.5.0
- Google Cloud SDK (gcloud CLI)
- Appropriate IAM permissions (see [Prerequisites](#prerequisites))

### 1. Clone Repository

```bash
git clone https://github.com/cloudon-one/gcp-landing-zone.git
cd gcp-landing-zone
```

### 2. Configure Authentication

```bash
# Authenticate with Google Cloud
gcloud auth login
gcloud auth application-default login

# Set your project
export PROJECT_ID="your-project-id"
gcloud config set project $PROJECT_ID
```

### 3. Enable Required APIs

```bash
gcloud services enable \
  compute.googleapis.com \
  container.googleapis.com \
  servicenetworking.googleapis.com \
  sqladmin.googleapis.com \
  redis.googleapis.com \
  accesscontextmanager.googleapis.com \
  iap.googleapis.com
```

### 4. Configure Backend Storage

Create a GCS bucket for Terraform state:

```bash
gsutil mb gs://your-tfstate-bucket
gsutil versioning set on gs://your-tfstate-bucket
```

### 5. Deploy Infrastructure

Deploy in the following order:

```bash
# 1. Deploy service projects
cd projects
terraform init
terraform plan
terraform apply

# 2. Deploy shared VPC
cd ../svpc
terraform init
terraform plan
terraform apply

# 3. Deploy IAM policies
cd ../iam
terraform init
terraform plan
terraform apply

# 4. Deploy VPC Service Controls
cd ../vpcsc
terraform init
terraform plan
terraform apply

# 5. Deploy bastion host
cd ../bastion
terraform init
terraform plan
terraform apply

# 6. Deploy GKE cluster
cd ../gke
terraform init
terraform plan
terraform apply

# 7. Deploy data services
cd ../sql
terraform init
terraform plan
terraform apply

cd ../redis
terraform init
terraform plan
terraform apply
```

## 🔧 Configuration

### Environment Variables

Create a `.env` file in the root directory:

```bash
export PROJECT_ID="your-project-id"
export BILLING_ACCOUNT="your-billing-account-id"
export ORGANIZATION_ID="your-org-id"
export FOLDER_ID="your-folder-id"
export REGION="us-central1"
export ZONE="us-central1-a"
```

### Terraform Variables

Each module has its own `variables.tf` and requires a `terraform.tfvars` file. Example for the main configuration:

```hcl
# Global settings
project_id = "your-project-id"
region     = "us-central1"
zone       = "us-central1-a"

# Network configuration
vpc_cidr = "10.0.0.0/8"
authorized_networks = [
  "10.160.0.0/16",  # gke-vpc
  "10.161.0.0/16"   # data-vpc
]

# Security settings
enable_private_nodes = true
enable_vpc_sc = true
enable_binary_authorization = true

# Monitoring and logging
enable_audit_logs = true
log_retention_days = 365
```

## 🏗️ Module Documentation

### Network Modules

#### [shared-vpc/](./shared-vpc/README.md)

Shared VPC implementation with:

- Private subnets for GKE and data services
- Cloud NAT for outbound internet access
- Private Google Access enabled
- VPC flow logs for security monitoring

#### [bastion/](./bastion/README.md)

Secure bastion host providing:

- IAP tunnel access for enhanced security
- SSH key management
- Audit logging
- Connection to private subnets

#### [iam/](./iam/README.md)

Identity and Access Management:

- Service accounts with minimal permissions
- IAM policies for different environments
- Workload Identity for GKE
- Custom roles for fintech compliance

#### [vpcsc/](./vpcsc/README.md)

VPC Service Controls:

- Data perimeter protection
- API access restrictions
- Ingress/egress policies
- Compliance with data residency requirements

### Service Modules

#### [projects/](./projects/README.md)

GCP project organization:

- Host project for shared VPC
- Service projects for workloads
- Billing account association
- Folder structure for governance

#### [gke/](./gke/README.md)

Google Kubernetes Engine:

- Private clusters with authorized networks
- Workload Identity enabled
- Network policies for micro-segmentation
- RBAC configuration
- Pod security standards

#### [sql/](./sql/README.md)

Cloud SQL databases:

- High availability configuration
- Automated backups
- Point-in-time recovery
- Private IP connectivity
- Encryption at rest

#### [redis/](./redis/README.md)

Redis instances:

- High availability with multiple zones
- VPC peering for private access
- Memory optimization
- Monitoring and alerting

## 🔐 Security

### Security Features

- **Encryption**: All data encrypted at rest and in transit
- **Network Security**: Private subnets, authorized networks, VPC Service Controls
- **Identity Management**: Service accounts, IAM policies, Workload Identity
- **Monitoring**: Comprehensive audit logging and security monitoring
- **Compliance**: Built-in controls for SOX, PCI DSS, and other regulations

### Security Best Practices

1. **Principle of Least Privilege**: All IAM policies follow minimal access principles
2. **Network Isolation**: Private clusters and subnets prevent unauthorized access
3. **Audit Logging**: All administrative actions are logged and monitored
4. **Encrypted Communication**: TLS encryption for all inter-service communication
5. **Regular Security Reviews**: Automated security scanning and manual reviews

For detailed security information, see [SECURITY.md](./SECURITY.md).

## 📊 Monitoring & Observability

### Built-in Monitoring

- **GKE Monitoring**: Cluster and node metrics via GMP
- **Database Monitoring**: Cloud SQL and Redis performance metrics
- **Network Monitoring**: VPC flow logs and firewall logs
- **Security Monitoring**: IAM policy changes and access patterns
- **Cost Monitoring**: Resource usage and billing alerts

### Alerting

Preconfigured alerts for:

- High resource utilization (>80% CPU/memory)
- Database connection failures
- Security policy violations
- Unusual network traffic patterns
- Cost threshold breaches

## 🔄 CI/CD Integration

### GitHub Actions

Example workflow for automated deployment:

```yaml
name: Deploy Infrastructure
on:
  push:
    branches: [main]
    paths: ['terraform/**']

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.5.0
      - name: Deploy
        run: |
          terraform init
          terraform plan
          terraform apply -auto-approve
```

### GitLab CI

Example `.gitlab-ci.yml`:

```yaml
stages:
  - validate
  - plan
  - apply

terraform-validate:
  stage: validate
  script:
    - terraform fmt -check
    - terraform validate

terraform-plan:
  stage: plan
  script:
    - terraform plan -out=plan.out

terraform-apply:
  stage: apply
  script:
    - terraform apply plan.out
  when: manual
  only:
    - main
```

## 🛠️ Operations

### Daily Operations

- Monitor cluster health via GKE dashboard
- Review security alerts and audit logs
- Check cost optimization recommendations
- Verify backup completion status

### Weekly Operations

- Review resource utilization trends
- Update security patches and dependencies
- Audit IAM permissions and access logs
- Test disaster recovery procedures

### Monthly Operations

- Security assessment and penetration testing
- Cost optimization review
- Capacity planning based on growth trends
- Update documentation and runbooks

## 🚨 Troubleshooting

### Common Issues

#### 1. Terraform Apply Fails

```bash
# Check provider versions
terraform version

# Reinitialize
terraform init -upgrade

# Check for resource conflicts
terraform import google_compute_network.vpc projects/PROJECT/global/networks/vpc-name
```

#### 2. GKE Cluster Access Issues

```bash
# Get cluster credentials
gcloud container clusters get-credentials CLUSTER_NAME --region=REGION

# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces
```

#### 3. Network Connectivity Issues

```bash
# Test connectivity from bastion
gcloud compute ssh bastion-host --zone=us-central1-a

# Check firewall rules
gcloud compute firewall-rules list

# Verify VPC peering
gcloud compute networks peerings list
```

### Debug Commands

```bash
# Terraform debugging
export TF_LOG=DEBUG
terraform apply

# GCP resource inspection
gcloud compute instances describe INSTANCE_NAME
gcloud container clusters describe CLUSTER_NAME

# Network debugging
gcloud compute routes list
gcloud dns managed-zones list
```

## 📈 Scaling

### Horizontal Scaling

- **GKE**: Auto-scaling node pools based on workload demands
- **Cloud SQL**: Read replicas for high-read workloads
- **Redis**: Cluster mode for distributed caching

### Vertical Scaling

- **Compute**: Machine type upgrades for higher performance
- **Storage**: SSD persistent disks for better IOPS
- **Network**: Premium network tier for lower latency

### Multi-Region Deployment

```hcl
# Multi-region configuration
regions = [
  {
    name = "us-central1"
    zones = ["us-central1-a", "us-central1-b", "us-central1-c"]
    primary = true
  },
  {
    name = "us-east1"  
    zones = ["us-east1-a", "us-east1-b", "us-east1-c"]
    primary = false
  }
]
```

## 💰 Cost Optimization

### Cost Monitoring

- **Budgets**: Set up billing alerts at 50%, 80%, and 100% of budget
- **Cost Allocation**: Use labels for department and environment tracking
- **Rightsizing**: Regular review of over-provisioned resources

### Optimization Strategies

1. **Preemptible Instances**: Use for non-critical workloads (50-80% cost savings)
2. **Committed Use Discounts**: 1 or 3-year commitments for predictable workloads
3. **Sustained Use Discounts**: Automatic discounts for long-running VMs
4. **Storage Classes**: Use nearline/coldline for infrequently accessed data

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](./CONTRIBUTING.md) for details on:

- Code standards and formatting
- Pull request process
- Testing requirements
- Documentation guidelines

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

## 📞 Support

- **Documentation**: Check module-specific README files
- **Issues**: Create GitHub issues for bugs and feature requests
- **Security**: Report security vulnerabilities via [SECURITY.md](./SECURITY.md)
- **Community**: Join our Slack channel for discussions

## 🔗 References

- [Google Cloud Architecture Framework](https://cloud.google.com/architecture/framework)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)
- [Cloud SQL Best Practices](https://cloud.google.com/sql/docs/mysql/best-practices)
- [VPC Design Best Practices](https://cloud.google.com/vpc/docs/best-practices)

---

**Last Updated**: September 2025  
**Version**: 1.0.0  
**Terraform Version**: >= 1.5.0  
**Google Provider Version**: >= 5.0.0
