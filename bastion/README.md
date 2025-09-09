# Bastion Host Manual

## Overview

The Bastion Host is a secured jump host deployed in Google Cloud Platform that provides secure access to private resources in your infrastructure. This document provides comprehensive instructions for setting up, accessing, and maintaining the bastion host.

**Infrastructure Details:**

- **Host Project**: `host-project`
- **Primary Region**: `us-central1`
- **Network**: Connected to gke-vpc and data-vpc (gke-subnet and data-subnet) with public NAT IP


## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Deployment](#deployment)
3. [Access Methods](#access-methods)
4. [Security Configuration](#security-configuration)
5. [User Management](#user-management)
6. [Monitoring and Logging](#monitoring-and-logging)
7. [Troubleshooting](#troubleshooting)
8. [Best Practices](#best-practices)
9. [Maintenance](#maintenance)

## Prerequisites

### Required Tools

- Google Cloud SDK (gcloud)
- Terraform >= 1.5.0
- SSH client
- Access to Google Cloud project with appropriate permissions

### Required Permissions

- Compute Engine Admin
- IAM Admin
- Network Admin
- Service Account Admin
- Identity-Aware Proxy Admin (for IAP tunnel access)

### Required APIs

Ensure the following APIs are enabled in your project:

- Compute Engine API
- Identity-Aware Proxy API
- Cloud Logging API
- Cloud Monitoring API

## Deployment

### 1. Configure Variables

Create a `terraform.tfvars` file in the `net-bastion` directory:

```hcl
# Backend configuration
net_svpc_backend_bucket = "tfstate-bucket"
net_svpc_backend_prefix = "net-svpc"
svc_projects_backend_bucket = "tfstate-bucket"
svc_projects_backend_prefix = "projects"

# Bastion configuration
region = "us-central1"
zone   = "a"

# Security configuration
authorized_networks = [
  "10.160.0.0/16",    # gke-vpc
  "10.161.0.0/16"     # data-vpc
]

ssh_keys = {
  "admin" = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC..."
}

enable_iap_tunnel = true
iap_user         = "user1@example.com"

# Optional: Enable NAT if needed
enable_nat = true
router_name = "router"
```

### 2. Initialize Terraform

```bash
cd bastion
terraform init 
terraform plan
terraform apply
```

### 4. Verify Deployment

```bash
terraform output
gcloud compute instances list --filter="name:bastion" --project=host-project
```

## Access Methods

### Method 1: IAP Tunnel (Recommended)

The IAP tunnel provides the most secure access method as it doesn't require the bastion host to have a public IP address.

#### Setup IAP Tunnel

```bash
terraform output bastion_iap_command

gcloud compute start-iap-tunnel fintech-bastion 22 \
  --local-host-port=localhost:2222 \
  --zone=us-central1-a \
  --project=host-project
```

#### Connect via IAP Tunnel

```bash
# In a new terminal, connect to the bastion host
ssh -p 2222 user@localhost

# Or use the full command with key
ssh -p 2222 -i ~/.ssh/your_private_key user@localhost
```

### Method 2: Direct SSH (if authorized networks configured)

```bash
# Get the SSH command from Terraform output
terraform output bastion_ssh_command

# Or use the command directly
gcloud compute ssh fintech-bastion \
  --zone=us-central1-a \
  --project=host-project
```

### Method 3: Using SSH Config

Create or update your `~/.ssh/config` file:

```
Host fintech-bastion
    HostName localhost
    Port 2222
    User your-username
    IdentityFile ~/.ssh/your_private_key
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

Then connect using:
```bash
ssh bastion
```

### Method 4: Connecting with OS Login

When OS Login is enabled, access is managed via IAM roles.
```bash
gcloud compute ssh [USERNAME]@[INSTANCE_NAME] --project=host-project --zone=us-central1-a
```

## GKE Cluster Access with Kubectl

The bastion host is pre-configured with `kubectl` and `gcloud`, allowing you to manage GKE clusters securely from within the project's network.

### 1. Connect to the Bastion Host

Use one of the methods described above (IAP Tunnel is recommended) to SSH into the bastion host.

### 2. Configure Kubectl

Once on the bastion host, run the following command to configure `kubectl` to communicate with your GKE cluster. The bastion's service account is used for authentication.

```bash
gcloud container clusters get-credentials gke-cluster --location us-central1
```

### 3. Verify Cluster Access

After configuring credentials, verify that you can connect to the cluster:
```bash
kubectl get nodes
kubectl get pods --all-namespaces
```

You can now use `kubectl` to manage your GKE resources as needed.

## Security Configuration

### SSH Key Management

#### Generate SSH Key Pair

```bash
# Generate a new SSH key pair
ssh-keygen -t ed25519 -C "your-email@example.com" -f ~/.ssh/bastion

# Or generate RSA key (if needed)
ssh-keygen -t rsa -b 4096 -C "your-email@example.com" -f ~/.ssh/bastion
```

#### Add Public Key to Bastion

1. Copy your public key:
```bash
cat ~/.ssh/bastion.pub
```

2. Add it to the `ssh_keys` variable in `terraform.tfvars`:
```hcl
ssh_keys = {
  "your-username" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI..."
}
```

3. Apply the changes:
```bash
terraform apply
```

### Network Security

#### Authorized Networks

Configure the `authorized_networks` variable to restrict access:

```hcl
authorized_networks = [
  "10.160.0.0/16",     # gke-vpc
  "10.161.0.0/16",     # data-vpc
]
```

#### Firewall Rules

The bastion host automatically creates firewall rules:

- `bastion-ssh`: Allows SSH from authorized networks
- `bastion-iap`: Allows SSH via IAP tunnel


### IAP Tunnel Security

#### Enable IAP for Users

```bash
gcloud projects add-iam-policy-binding host-project \
  --member="user:user1@example.com" \
  --role="roles/iap.tunnelResourceAccessor"
```

#### Verify IAP Access

```bash
gcloud projects get-iam-policy host-project \
  --flatten="bindings[].members" \
  --filter="bindings.role=roles/iap.tunnelResourceAccessor"
```

## User Management

### Adding New Users

1. **Generate SSH Key for User**:
```bash
ssh-keygen -t ed25519 -C "user1@example.com"
```

2. **Add Public Key to Configuration**:

```hcl
ssh_keys = {
  "admin" = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC..."
  "user1" = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC..."
  "newuser" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI..." # New user
}
```

3. **Apply Changes**:

```bash
terraform apply
```

### Removing Users

1. Remove the user's SSH key from `terraform.tfvars`
2. Apply the changes:
```bash
terraform apply
```

### User Access Verification

```bash
ssh -p 2222 user@localhost
cat ~/.ssh/authorized_keys
groups
```

## Monitoring and Logging

### Access Logs

#### Local Logs

```bash
sudo tail -f /var/log/auth.log
sudo tail -f /var/log/bastion-access.log
sudo tail -f /var/log/fail2ban.log
```

#### Cloud Logging

```bash
gcloud logging read "resource.type=gce_instance AND resource.labels.instance_name=fintech-bastion" \
  --project=host-project \
  --limit=50
```

### VPC Flow Logs

The shared VPC has VPC flow logs enabled for network monitoring:

```bash
gcloud logging read "resource.type=gce_subnetwork AND resource.labels.subnetwork_name=bastion-subnet" \
  --project=host-project \
  --limit=50
```

### Monitoring

#### System Resources

```bash
htop
df -h
free -h
ps aux
```

#### Security Monitoring

```bash
sudo fail2ban-client status
sudo fail2ban-client status sshd
sudo ausearch -k ssh_config
```

### Alerting

Set up Cloud Monitoring alerts for:

- High CPU usage (>80%)
- High memory usage (>80%)
- High disk usage (>90%)
- Failed SSH attempts
- Unusual access patterns

## Troubleshooting

### Common Issues

#### 1. SSH Connection Refused

**Symptoms**: `ssh: connect to host localhost port 2222: Connection refused`

**Solutions**:

```bash
ps aux | grep iap

gcloud compute start-iap-tunnel bastion 22 \
  --local-host-port=localhost:2222 \
  --zone=us-central1-a \
  --project=host-project

gcloud compute firewall-rules list --filter="name:bastion" --project=host-project
```

#### 2. Permission Denied

**Symptoms**: `Permission denied (publickey)`

**Solutions**:

```bash
ssh-keygen -l -f ~/.ssh/your_private_key

ssh -p 2222 user@localhost "cat ~/.ssh/authorized_keys"

ssh -p 2222 -i ~/.ssh/your_private_key user@localhost
```

#### 3. IAP Tunnel Issues

**Symptoms**: `ERROR: (gcloud.compute.start-iap-tunnel) PERMISSION_DENIED`

**Solutions**:

```bash
gcloud projects get-iam-policy host-project \
  --flatten="bindings[].members" \
  --filter="bindings.role=roles/iap.tunnelResourceAccessor"

gcloud projects add-iam-policy-binding host-project \
  --member="user:your-email@fintech.com" \
  --role="roles/iap.tunnelResourceAccessor"
```

#### 4. Instance Not Starting

**Symptoms**: Instance stuck in "Starting" state

**Solutions**:

```bash
gcloud compute instances get-serial-port-output bastion \
  --zone=us-central1-a \
  --project=host-project

gcloud logging read "resource.type=gce_instance AND resource.labels.instance_name=bastion" \
  --project=host-project \
  --limit=10
```

### Debug Commands

#### Network Connectivity

```bash
ping -c 4 8.8.8.8

nslookup google.com

traceroute google.com
```

#### SSH Debugging

```bash
ssh -v -p 2222 user@localhost

ssh -p 2222 user@localhost "sudo cat /etc/ssh/sshd_config.d/bastion.conf"
```

#### System Debugging

```bash
sudo systemctl status ssh
sudo systemctl status fail2ban
sudo systemctl status rsyslog

sudo journalctl -u ssh
sudo journalctl -u fail2ban
```

## Best Practices

### Security Best Practices

1. **Use IAP Tunnel**: Always prefer IAP tunnel over direct SSH access
2. **Strong SSH Keys**: Use Ed25519 or RSA 4096-bit keys
3. **Regular Key Rotation**: Rotate SSH keys every 90 days
4. **Network Restrictions**: Only allow access from authorized networks
5. **Monitor Access**: Regularly review access logs
6. **Keep Updated**: Ensure automatic security updates are enabled

### Operational Best Practices

1. **Backup Configuration**: Regularly backup SSH keys and configuration
2. **Documentation**: Keep access procedures documented
3. **User Training**: Train users on secure access practices
4. **Incident Response**: Have procedures for security incidents
5. **Regular Audits**: Conduct regular security audits

### Performance Best Practices

1. **Resource Monitoring**: Monitor CPU, memory, and disk usage
2. **Log Rotation**: Ensure logs are rotated to prevent disk space issues
3. **Connection Limits**: Limit concurrent SSH connections
4. **Timeout Configuration**: Configure appropriate connection timeouts

## Maintenance

### Regular Maintenance Tasks

#### Weekly

- Review access logs
- Check system resources
- Verify backup procedures

#### Monthly

- Rotate SSH keys
- Update system packages
- Review security configurations
- Audit user access

#### Quarterly

- Security assessment
- Performance review
- Documentation updates
- Disaster recovery testing

### Backup Procedures

#### SSH Keys Backup

```bash
cp ~/.ssh/fintech_bastion* /secure/backup/location/

terraform state pull > terraform-state-backup.json
```

#### Configuration Backup

```bash
tar -czf bastion-config-backup.tar.gz \
  terraform.tfvars \
  backend.tf \
  main.tf \
  variables.tf
```

### Update Procedures

#### Terraform Updates

```bash
terraform init -upgrade
terraform plan
terraform apply
```

#### System Updates

```bash
ssh -p 2222 user@localhost

sudo apt update
sudo apt list --upgradable
sudo apt upgrade -y
```

### Disaster Recovery

#### Instance Recovery

```bash
cd net-bastion
terraform apply
terraform output
```

#### Configuration Recovery

```bash
cp /secure/backup/location/terraform.tfvars .
cp /secure/backup/location/ssh_keys/* ~/.ssh/
terraform apply
```

## Support

For issues or questions regarding the bastion host:

1. Check this manual first
2. Review the troubleshooting section
3. Check Cloud Logging for error messages
4. Contact the infrastructure team
5. Create an issue in the project repository

## References

- [Google Cloud IAP Documentation](https://cloud.google.com/iap/docs)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [SSH Best Practices](https://www.ssh.com/academy/ssh/best-practices)
- [Fail2ban Documentation](https://www.fail2ban.org/wiki/index.php/Main_Page) 
