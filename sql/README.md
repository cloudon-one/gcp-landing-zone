# fintech Production Cloud SQL Infrastructure

This directory contains the Terraform configuration for deploying and managing Google Cloud SQL instances in the fintech production environment.

## Overview

The Cloud SQL infrastructure provides:

- **High Availability**: Regional deployment with automatic failover
- **Security**: Private network configuration with SSL enforcement
- **Backup & Recovery**: Automated backups with point-in-time recovery
- **Monitoring**: Query insights and comprehensive monitoring
- **Scalability**: Read replicas for performance optimization

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GKE Cluster   │    │  Cloud SQL      │    │  Read Replicas  │
│  (10.160.4.0/22)│◄──►│  Primary        │◄──►│  (Multi-region) │
└─────────────────┘    │  (Private IP)   │    └─────────────────┘
                       └─────────────────┘
                                │
                       ┌─────────────────┐
                       │  data-subnet    │
                       │  (10.161.4.0/22)│
                       └─────────────────┘
```

## Prerequisites

1. **Terraform**: Version >= 1.5.0
2. **Google Cloud Provider**: Version >= 5.0
3. **GCP Project**: fintech SQL project with necessary APIs enabled
4. **Network Infrastructure**: VPC and subnets from `net-svcp` module
5. **Project Structure**: Service projects from `svc-projects` module

## Configuration

### 1. Backend Configuration

The Terraform state is stored in Google Cloud Storage.

```bash
terraform init
```

### 2. Variables Configuration

Edit `terraform.tfvars` with your specific values.

## Deployment

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Plan the Deployment

```bash
terraform plan -out=tfplan
```

### 3. Apply the Configuration

```bash
terraform apply tfplan
```

## Resources Created

### Cloud SQL Instances

- **Primary Instances**: High-availability database instances
- **Read Replicas**: Cross-region replicas for scalability
- **Databases**: Application and analytics databases
- **Users**: Database users with appropriate permissions

### Security Resources

- **Service Accounts**: Cloud SQL admin service account
- **IAM Roles**: Appropriate permissions for database management
- **Firewall Rules**: Network access control for database connections

## Database Instances

### PostgreSQL Analytics Database

- **Purpose**: Analytics and reporting
- **Version**: PostgreSQL 15
- **Availability**: Regional (high availability)
- **Databases**: `fintech_analytics`, `fintech_reporting`
- **Read Replicas**: Cross-region replica in europe-west4

## Security Features

### Network Security

- **Private IP**: All instances use private IP addresses
- **VPC Integration**: Connected to fintech data-vpc
- **SSL Enforcement**: All connections require SSL/TLS
- **Authorized Networks**: Restricted access to specific IP ranges

### Data Protection

- **Deletion Protection**: Prevents accidental deletion
- **Backup Retention**: 7-day backup retention
- **Point-in-Time Recovery**: Granular recovery capabilities

## Monitoring & Maintenance

### Backup Schedule

- **Daily Backups**: 2:00 AM UTC
- **Retention**: 7 days
- **Point-in-Time Recovery**: Enabled

### Maintenance Windows

- **Schedule**: Sundays at 2:00 AM UTC
- **Update Track**: Stable channel

## Connection Information

## Connection Strings

### Connect PostgreSQL instance from bastion-host with sql-admin service account key:

```bash
./cloud-sql-proxy --credentials-file /opt/gcp-keys/prod/sql-admin.json \
  data-project:us-central1:cloud-sql
```

## Troubleshooting

### Common Issues

#### Connection Issues

```bash
gcloud compute firewall-rules list --filter="name=allow-cloudsql-access"
gcloud compute instances describe <instance-name> --zone=<zone>
```

#### Backup Issues

```bash
gcloud sql backups list --instance=<instance-name>
```

## Support

For issues and questions:

- **DevOps Team**: fintech-devops
- **Documentation**: [Cloud SQL Documentation](https://cloud.google.com/sql/docs)
- **Google Cloud Support**: [Support Portal](https://cloud.google.com/support) 