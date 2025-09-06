# Redis Service (Memorystore)

This Terraform configuration deploys Google Cloud Memorystore Redis instances for the fintech production environment with private network connectivity and comprehensive security features.

## Overview

The Redis service provides high-performance, managed Redis instances with:

- **Private Network Access**: All instances are deployed with private IP addresses within the data VPC
- **High Availability**: STANDARD_HA tier with automatic failover
- **Security**: TLS encryption, authentication, and firewall rules
- **Persistence**: RDB snapshots for data durability
- **Scalability**: Configurable memory sizes and read replicas

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GKE Cluster   │    │   Data VPC      │    │   IAP Tunnel    │
│  10.160.0.0/16  │    │  10.161.0.0/16  │    │ 35.235.240.0/20 │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌────────────▼───────────── ┐
                    │    Redis Instances        │
                    │     10.161.12.0/28         │
                    │                           │
                    └───────────────────────────┘
```

## Features

- **🔒 Private Network**: All Redis instances use private IP addresses
- **🛡️ Security**: TLS encryption and authentication enabled
- **💾 Persistence**: RDB snapshots every 12 hours
- **📊 High Availability**: STANDARD_HA tier with automatic failover
- **🔧 Maintenance**: Sunday 2 AM maintenance window
- **📈 Scalability**: Configurable memory sizes and replica counts
- **🌐 Network Access**: Firewall rules for GKE, data VPC, and IAP access

## Configuration

### Default Configuration

The service creates a main Redis instance with the following specifications:

- **Instance Name**: `redis`
- **Tier**: `STANDARD_HA` (High Availability)
- **Memory**: 5 GB
- **Redis Version**: 7.0
- **Replicas**: 1 read replica
- **Network**: Private service access within data VPC
- **CIDR Block**: 10.161.12.0/28

### Redis Configuration

Default Redis configuration parameters:

```hcl
redis_configs = {
  maxmemory-policy = "allkeys-lru"  # Evict least recently used keys
  timeout          = "300"          # Client timeout in seconds
}
```

**Note**: The `maxmemory`, `save`, and `tcp-keepalive` parameters are not supported in Redis 7.0. Memory management and persistence are handled automatically by Google Cloud Memorystore based on the `memory_size_gb` and `persistence_config` settings.

### Firewall Rules

The service creates three firewall rules for secure access:

1. **GKE Access**: Allows Redis access from GKE cluster (10.160.0.0/16)
2. **Data VPC Access**: Allows Redis access from data VPC (10.161.0.0/16)
3. **IAP Access**: Allows Redis access from IAP tunnel (35.235.240.0/20)

## Usage

### Basic Deployment

```bash
terraform init
terraform plan
terraform apply
```

### Custom Configuration

To customize the Redis configuration, modify the `redis_instances_config` variable:

```hcl
variable "redis_instances_config" {
  default = {
    main = {
      tier           = "STANDARD_HA"
      memory_size_gb = 5  # Increase memory to 10GB
      redis_version  = "REDIS_7_0"
      replica_count  = 2   # Add more replicas
      redis_configs = {
        maxmemory-policy = "volatile-lru"
        timeout          = "600"
      }
    }
    cache = {  # Add additional Redis instance
      tier           = "BASIC"
      memory_size_gb = 2
      redis_version  = "REDIS_7_0"
      replica_count  = 0
      redis_configs = {
        maxmemory-policy = "allkeys-lru"
        timeout          = "300"
      }
    }
  }
}
```

## Dependencies

This service depends on the following Terraform states:

- **net-svcp**: For VPC network configuration
- **svc-projects**: For project IDs
- **net-iam**: For IAM configuration

## Outputs

The service provides the following outputs:

- `redis_instances`: Map of all Redis instances with connection details
- `main_redis_instance`: Details of the main Redis instance
- `redis_auth_string`: Authentication string (sensitive)
- `redis_configs`: Redis configuration parameters
- `maintenance_policies`: Maintenance window information
- `persistence_configs`: Persistence configuration
- `firewall_rules`: Firewall rules created for access control

## Security Considerations

- **Private Network**: All Redis instances use private IP addresses
- **Authentication**: OSS Redis AUTH is enabled by default
- **Encryption**: TLS encryption is enabled for all connections
- **Firewall Rules**: Access is restricted to specific network ranges
- **Authorized Networks**: Only the data VPC is authorized for access

## Monitoring and Maintenance

- **Maintenance Window**: Sunday 2 AM (configurable)
- **Persistence**: RDB snapshots every 12 hours
- **High Availability**: Automatic failover with STANDARD_HA tier
- **Monitoring**: Cloud Monitoring integration for metrics and alerts

## Troubleshooting

### Common Issues

1. **Connection Refused**: Check firewall rules and network connectivity
2. **Authentication Failed**: Verify the AUTH string from outputs
3. **Memory Issues**: Monitor memory usage and adjust `maxmemory` settings
4. **Performance Issues**: Consider adding read replicas or increasing memory

### Useful Commands

```bash
terraform output main_redis_instance
terraform output redis_auth_string
redis-cli -h <redis-host> -p 6379 -a <auth-string> ping
```

## Cost Optimization

- **Memory Sizing**: Start with smaller instances and scale as needed
- **Tier Selection**: Use BASIC tier for development, STANDARD_HA for production
- **Replica Count**: Only add replicas when read scaling is needed
- **Monitoring**: Use Cloud Monitoring to track usage and costs

## Related Documentation

- [Google Cloud Memorystore Documentation](https://cloud.google.com/memorystore/docs/redis)
- [Redis Configuration Reference](https://redis.io/topics/config)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs) 