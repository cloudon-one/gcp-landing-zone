# Network Shared VPC Management

This Terraform configuration manages Shared VPC (Virtual Private Cloud) networks for the fintech production infrastructure, providing a centralized networking foundation for multiple service projects.

## Overview

The `net-svpc` module creates and manages two primary VPC networks:

- **GKE VPC**: Dedicated network for Google Kubernetes Engine workloads
- **Data VPC**: Dedicated network for data processing and storage services

Both VPCs are configured as Shared VPC host projects, allowing service projects to attach and use the network resources while maintaining centralized network management.

## Components

### 1. GKE VPC Network

- **Purpose**: Hosts Kubernetes clusters and containerized applications
- **Subnets**:
  - **GKE Subnet**: Primary subnet for GKE nodes (10.160.4.0/22)
  - **Proxy Subnet**: Internal HTTPS load balancer subnet (10.160.0.0/24)
  - **Control Plane Subnet**: GKE control plane subnet (10.160.16.0/24)
- **Features**: Cloud NAT, firewall rules, VPC peering, private DNS

### 2. Data VPC Network

- **Purpose**: Hosts data processing, analytics, and storage services
- **Subnets**:
  - **Data Subnet**: Primary subnet for data services (10.160.8.0/22)
  - **Proxy Subnet**: Internal HTTPS load balancer subnet (10.160.12.0/24)
- **Features**: Cloud NAT, firewall rules, VPC peering, private service access

### 3. Shared VPC Configuration

- **Host Projects**: Both VPCs are configured as Shared VPC hosts
- **Service Projects**: GKE and Data projects attach to respective VPCs
- **IAM Bindings**: Subnet-level IAM permissions for service projects

### 4. Network Services

- **Cloud NAT**: Outbound internet access for private resources
- **Firewall Rules**: Comprehensive ingress/egress traffic control
- **VPC Peering**: Cross-VPC connectivity between GKE and Data networks
- **Private DNS**: Internal DNS zones for service discovery

## Usage

### Basic Configuration

```hcl
module "shared_vpc" {
  source = "./shared-vpc"

  # Project Configuration
  project_id = "host-project"
  folder_id  = "1234567890"
  region     = "us-central1"

  # VPC Names
  gke_vpc_name = "gke-vpc"
  data_vpc_name = "data-vpc"

  # GKE Subnet Configuration
  gke_subnet = {
    name          = "gke-subnet"
    ip_cidr_range = "10.160.4.0/22"
    secondary_ip_ranges = [
      {
        range_name    = "pods"
        ip_cidr_range = "10.160.128.0/17"
      },
      {
        range_name    = "services"
        ip_cidr_range = "10.160.8.0/22"
      }
    ]
    private_ip_google_access = true
    log_config = {
      aggregation_interval = "INTERVAL_10_MIN"
      flow_sampling        = 0.5
      metadata            = "INCLUDE_ALL_METADATA"
    }
  }

  # Data Subnet Configuration
  data_subnet = {
    name          = "data-subnet"
    ip_cidr_range = "10.160.8.0/22"
    secondary_ip_ranges = []
    private_ip_google_access = true
    log_config = {
      aggregation_interval = "INTERVAL_10_MIN"
      flow_sampling        = 0.5
      metadata            = "INCLUDE_ALL_METADATA"
    }
  }

  # Service Projects
  gke_service_projects = {
    gke = "gke-project"
  }
  
  data_service_projects = {
    data = "data-project"
  }

  # Labels
  labels = {
    environment = "production"
    team        = "devops"
    managed_by  = "terraform"
  }
}
```

### Advanced Configuration

```hcl
module "shared_vpc" {
  source = "./shared-vpc"

  # Cloud NAT Configuration
  gke_cloud_nat_config = {
    router_name                        = "gke-router"
    router_region                      = "us-central1"
    router_asn                         = 64514
    nat_name                           = "gke-nat"
    nat_ip_allocate_option             = "AUTO_ONLY"
    source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
    log_config = {
      enable = true
      filter = "ERRORS_ONLY"
    }
  }

  data_cloud_nat_config = {
    router_name                        = "data-router"
    router_region                      = "us-central1"
    router_asn                         = 64514
    nat_name                           = "data-nat"
    nat_ip_allocate_option             = "AUTO_ONLY"
    source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
    log_config = {
      enable = true
      filter = "ERRORS_ONLY"
    }
  }

  # Firewall Rules
  gke_firewall_rules = {
    allow-internal = {
      name          = "allow-internal-traffic"
      description   = "Allow internal communication between GKE subnets"
      direction     = "INGRESS"
      disabled      = false
      enable_logging = true
      priority      = 1000
      source_ranges = ["10.160.0.0/16"]
      target_tags   = []
      allow = [
        {
          protocol = "tcp"
          ports    = ["0-65535"]
        },
        {
          protocol = "udp"
          ports    = ["0-65535"]
        },
        {
          protocol = "icmp"
          ports    = []
        }
      ]
      deny = []
    }
    
    allow-iap = {
      name          = "allow-iap-access"
      description   = "Allow Google Cloud Identity-Aware Proxy"
      direction     = "INGRESS"
      disabled      = false
      enable_logging = true
      priority      = 1000
      source_ranges = ["35.235.240.0/20"]
      target_tags   = ["iap-access"]
      allow = [
        {
          protocol = "tcp"
          ports    = ["22", "3389"]
        }
      ]
      deny = []
    }
  }

  # VPC Peering Configuration
  gke_vpc_peering_config = {
    to-data-vpc = {
      name                 = "gke-to-data-peering"
      peer_network         = "projects/host-project/global/networks/data-vpc"
      auto_create_routes   = true
      export_custom_routes = true
      import_custom_routes = true
    }
  }

  data_vpc_peering_config = {
    to-gke-vpc = {
      name                 = "data-to-gke-peering"
      peer_network         = "projects/host-project/global/networks/gke-vpc"
      auto_create_routes   = true
      export_custom_routes = true
      import_custom_routes = true
    }
  }

  # Private Service Access
  data_private_service_access_ranges = {
    cloudsql = {
      name          = "cloudsql-private-access"
      ip_cidr_range = "10.160.32.0/24"
    }
  }

  # DNS Configuration
  dns_config = {
    internal-zone = {
      name        = "internal"
      dns_name    = "prod.internal."
      description = "Internal DNS zone for production services"
      networks = [
        "projects/host-project/global/networks/gke-vpc",
        "projects/host-project/global/networks/data-vpc"
      ]
    }
  }
}
```

## Configuration Variables

### Core Configuration

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|:--------:|
| `project_id` | The ID of the project where VPCs will be created | `string` | n/a | yes |
| `folder_id` | The folder ID where projects will be created | `string` | n/a | yes |
| `region` | The region where VPCs will be created | `string` | n/a | yes |
| `gke_vpc_name` | The name of the GKE VPC network | `string` | `"gke-vpc"` | no |
| `data_vpc_name` | The name of the Data VPC network | `string` | `"data-vpc"` | no |

### Subnet Configuration

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|:--------:|
| `gke_subnet` | Configuration for the GKE subnet | `object` | n/a | yes |
| `gke_proxy_subnet` | Configuration for the GKE proxy subnet | `object` | n/a | yes |
| `gke_control_plane_subnet` | Configuration for the GKE control plane subnet | `object` | n/a | yes |
| `data_subnet` | Configuration for the data subnet | `object` | n/a | yes |
| `data_proxy_subnet` | Configuration for the data proxy subnet | `object` | n/a | yes |

### Cloud NAT Configuration

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|:--------:|
| `gke_cloud_nat_config` | Configuration for GKE Cloud NAT | `object` | n/a | yes |
| `data_cloud_nat_config` | Configuration for Data Cloud NAT | `object` | n/a | yes |

### Firewall Configuration

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|:--------:|
| `gke_firewall_rules` | Map of GKE firewall rules to create | `map(object)` | `{}` | no |
| `data_firewall_rules` | Map of Data firewall rules to create | `map(object)` | `{}` | no |

### Shared VPC Configuration

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|:--------:|
| `gke_service_projects` | Map of service projects to attach to GKE VPC | `map(string)` | `{}` | no |
| `data_service_projects` | Map of service projects to attach to Data VPC | `map(string)` | `{}` | no |
| `gke_subnet_iam_bindings` | IAM bindings for GKE subnets | `map(object)` | `{}` | no |
| `data_subnet_iam_bindings` | IAM bindings for Data subnets | `map(object)` | `{}` | no |

### VPC Peering Configuration

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|:--------:|
| `gke_vpc_peering_config` | VPC peering configuration for GKE VPC | `map(object)` | `{}` | no |
| `data_vpc_peering_config` | VPC peering configuration for Data VPC | `map(object)` | `{}` | no |

### DNS Configuration

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|:--------:|
| `dns_config` | Private DNS zones configuration | `map(object)` | `{}` | no |

### Private Service Access

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|:--------:|
| `data_private_service_access_ranges` | Private service access ranges for Data VPC | `map(object)` | `{}` | no |

## Outputs

| Output | Description |
|--------|-------------|
| `gke_vpc_id` | The ID of the GKE VPC |
| `gke_vpc_self_link` | The self-link of the GKE VPC |
| `gke_subnet_ids` | Map of GKE subnet IDs |
| `gke_subnet_self_links` | Map of GKE subnet self-links |
| `data_vpc_id` | The ID of the Data VPC |
| `data_vpc_self_link` | The self-link of the Data VPC |
| `data_subnet_ids` | Map of Data subnet IDs |
| `data_subnet_self_links` | Map of Data subnet self-links |
| `gke_cloud_nat_ips` | List of GKE Cloud NAT external IPs |
| `data_cloud_nat_ips` | List of Data Cloud NAT external IPs |
| `gke_router_id` | The ID of the GKE Cloud Router |
| `data_router_id` | The ID of the Data Cloud Router |

## Network Design

### IP Address Allocation

```
GKE VPC (10.160.0.0/16):
├── GKE Subnet: 10.160.4.0/22 (1,024 IPs)
├── Proxy Subnet: 10.160.0.0/24 (256 IPs)
├── Control Plane: 10.160.16.0/24 (256 IPs)
├── Pods: 10.160.128.0/17 (32,768 IPs)
└── Services: 10.160.8.0/22 (1,024 IPs)

Data VPC (10.161.0.0/16):
├── Data Subnet: 10.161.8.0/22 (1,024 IPs)
├── Proxy Subnet: 10.161.12.0/24 (256 IPs)
└── Cloud SQL: 10.161.32.0/24 (256 IPs)
```

### Firewall Rules

#### Default Rules

- **allow-internal**: Internal communication between subnets
- **allow-iap**: Identity-Aware Proxy access for SSH/RDP
- **deny-all-egress**: Default deny for outbound traffic
- **allow-nat-egress**: Allow outbound traffic through Cloud NAT

#### Custom Rules

- **allow-gke-master**: GKE control plane access
- **allow-health-checks**: Load balancer health check access
- **allow-cloud-sql**: Cloud SQL access from authorized sources

## Security Considerations

### Network Segmentation

- GKE and Data workloads are isolated in separate VPCs
- VPC peering provides controlled cross-VPC communication
- Subnet-level IAM controls access to network resources

### Access Control

- All external access is controlled through Identity-Aware Proxy
- Firewall rules follow the principle of least privilege
- Private Google Access enables secure API communication

### Monitoring and Logging

- VPC flow logs capture network traffic for analysis
- Firewall rule logging provides visibility into allowed/denied traffic
- Cloud NAT logs track outbound internet access

## Dependencies

This module has no external dependencies but provides outputs consumed by:

- `gke` - GKE cluster deployment
- `sql` - Cloud SQL instance deployment
- `redis` - Memorystore Redis deployment

## Troubleshooting

### Common Issues

1. **VPC Peering Conflicts**
   - Ensure no overlapping IP ranges between VPCs
   - Verify that both VPCs are in the same project
   - Check that peering is established in both directions

2. **Subnet IAM Issues**
   - Verify service projects have the correct IAM roles
   - Check that subnets are properly shared with service projects
   - Ensure service accounts have the required permissions

3. **DNS Resolution Problems**
   - Verify private DNS zones are properly configured
   - Check that VPCs are attached to DNS zones
   - Ensure DNS records are correctly configured

### Debugging Commands

```bash
gcloud compute networks peerings list --network=gke-vpc --project=PROJECT_ID
gcloud compute networks subnets get-iam-policy SUBNET_NAME --region=REGION --project=PROJECT_ID
gcloud compute firewall-rules list --project=PROJECT_ID
nslookup SERVICE_NAME.prod.internal
```

## Related Documentation

- [Google Cloud VPC Documentation](https://cloud.google.com/vpc/docs)
- [Shared VPC](https://cloud.google.com/vpc/docs/shared-vpc)
- [VPC Peering](https://cloud.google.com/vpc/docs/vpc-peering)
- [Cloud NAT](https://cloud.google.com/nat/docs)
- [Private DNS](https://cloud.google.com/dns/docs/zones) 
