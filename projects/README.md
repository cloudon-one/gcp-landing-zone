# Service Projects Configuration

This module manages the creation of service projects in Google Cloud Platform with automatic VPC connections based on project type.

## Overview

The service projects module creates GCP projects and automatically connects them to the appropriate VPC networks based on their type:
- **GKE projects** (`type = "gke"`) → Connected to `gke-vpc` with access to GKE subnets (excluding control-plane subnet)
- **Data projects** (`type = "data"`) → Connected to `data-vpc` with access to data subnets

## Features

### Automatic VPC Connections
- Service projects are automatically connected to the appropriate VPC based on their type
- Subnet IAM bindings are dynamically generated to grant network access
- No manual configuration required for new service projects

### Project Type Support
- **GKE Projects**: For Kubernetes workloads, connected to GKE VPC
- **Data Projects**: For data processing workloads, connected to Data VPC

### Security
- Default network creation is disabled at the folder level
- Projects are created with `auto_create_network = false`
- Appropriate APIs are automatically enabled based on project type

## Configuration

### Basic Configuration

```hcl
service_projects = {
  gke = {
    name = "gke-project"
    type = "gke"
    apis = [] # Uses default APIs for gke type
  }
  data = {
    name = "data-project"
    type = "data"
    apis = [] # Uses default APIs for data type
  }
}
```

### Adding New Service Projects

To add a new service project, simply add it to the `service_projects` map:

```hcl
service_projects = {
  gke = {
    name = "gke-project"
    type = "gke"
  }
  data = {
    name = "data-project"
    type = "data"
  }
  # New GKE project
  gke-backup = {
    name = "gke-backup-project"
    type = "gke"
  }
  # New data project
  analytics = {
    name = "analytics-project"
    type = "data"
  }
}
```

The new projects will automatically:

1. Be created with appropriate APIs enabled
2. Be connected to the correct VPC (GKE or Data)
3. Get subnet access permissions
4. Be excluded from the control-plane subnet (for GKE projects)

## Default APIs

### GKE Projects

- `container.googleapis.com`
- `compute.googleapis.com`
- `monitoring.googleapis.com`
- `logging.googleapis.com`
- `cloudtrace.googleapis.com`

### Data Projects

- `compute.googleapis.com`
- `dataflow.googleapis.com`
- `composer.googleapis.com`
- `bigquery.googleapis.com`
- `storage.googleapis.com`
- `sql-component.googleapis.com`
- `sqladmin.googleapis.com`
- `pubsub.googleapis.com`
- `dataproc.googleapis.com`

## Outputs

- `service_projects`: Map of all service projects with their details
- `service_project_ids`: Map of service project IDs
- `host_project_id`: Host project ID
- Legacy outputs for backward compatibility

## VPC Integration

This module integrates with the `net-svpc` module to automatically:

1. Connect service projects to the appropriate VPC
2. Grant subnet access permissions
3. Exclude GKE projects from control-plane subnet access
4. Update IAM bindings when new projects are added

## Usage

1. Define your service projects in `terraform.tfvars`
2. Run `terraform plan` to see the changes
3. Run `terraform apply` to create the projects
4. The projects will automatically be connected to the appropriate VPCs

## Security Notes

- All projects have default network creation disabled
- Projects are created in the specified folder with appropriate labels
- Service accounts are automatically granted network access based on project type
- GKE control-plane subnet access is explicitly excluded for security