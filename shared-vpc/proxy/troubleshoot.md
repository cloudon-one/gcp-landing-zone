# Monitoring and Troubleshooting Guide

## Monitoring Commands

### Check Proxy VM Status

```bash
# SSH to proxy VM
gcloud compute ssh database-proxy --zone=europe-central2-a --project=host-project

# Check all proxy services
sudo supervisorctl status

# Check specific service logs
sudo tail -f /var/log/redis-proxy.out.log
sudo tail -f /var/log/postgres-primary-proxy.out.log
sudo tail -f /var/log/postgres-replica-proxy.out.log

# Check error logs
sudo tail -f /var/log/redis-proxy.err.log
sudo tail -f /var/log/postgres-primary-proxy.err.log
sudo tail -f /var/log/postgres-replica-proxy.err.log
```

### Network Connectivity Tests

```bash
# Test from proxy VM to backend services
nc -zv 10.161.12.4 6378  # Redis
nc -zv 10.161.1.2 5432   # PostgreSQL Primary
nc -zv 10.161.2.2 5432   # PostgreSQL Replica

# Test proxy services locally
nc -zv localhost 6379   # Redis proxy
nc -zv localhost 5432   # PostgreSQL primary proxy  
nc -zv localhost 5433   # PostgreSQL replica proxy

# Check listening ports
sudo netstat -tlnp | grep -E "(6379|5432|5433)"
```

### GKE Pod Connectivity Tests

```bash
# Create test pod
kubectl run netshoot --image=nicolaka/netshoot --rm -it -- /bin/bash

# Inside pod - test proxy connectivity
PROXY_IP="10.161.0.x"  # Replace with actual IP
nc -zv $PROXY_IP 6379  # Redis
nc -zv $PROXY_IP 5432  # PostgreSQL Primary
nc -zv $PROXY_IP 5433  # PostgreSQL Replica

# Test with application tools
redis-cli -h $PROXY_IP -p 6379 ping
psql -h $PROXY_IP -p 5432 -U username -d database -c "SELECT 1"
psql -h $PROXY_IP -p 5433 -U username -d database -c "SELECT 1"
```

## Common Issues and Solutions

### Issue 1: Proxy Services Not Starting

```bash
# Check supervisor status
sudo supervisorctl status

# Restart services
sudo supervisorctl restart redis-proxy
sudo supervisorctl restart postgres-primary-proxy
sudo supervisorctl restart postgres-replica-proxy

# Check if ports are in use
sudo lsof -i :6379
sudo lsof -i :5432
sudo lsof -i :5433
```

### Issue 2: Connection Refused from GKE

```bash
# Check firewall rules
gcloud compute firewall-rules list --filter="name~gke.*proxy"

# Verify proxy VM IP is in data-vpc range
gcloud compute instances describe database-proxy \
    --zone=us-central1-a \
    --format="get(networkInterfaces[0].networkIP)"

# Test from GKE node (not pod)
kubectl get nodes -o wide
# SSH to GKE node and test connectivity
```

### Issue 3: Backend Service Connectivity

```bash
# From proxy VM, test backend services
ping 10.161.12.4  # Redis
ping 10.161.1.2   # PostgreSQL Primary
ping 10.161.2.2   # PostgreSQL Replica

# Check DNS resolution
nslookup 10.161.12.4
nslookup 10.161.1.2
nslookup 10.161.2.2

# Test with specific tools
redis-cli -h 10.161.12.4 -p 6378 ping
psql -h 10.161.1.2 -p 5432 -U username -d database -c "SELECT 1"
psql -h 10.161.2.2 -p 5432 -U username -d database -c "SELECT 1"
```

### Issue 4: High Latency/Performance

```bash
# Monitor proxy performance
sudo iotop
sudo htop

# Check connection counts
sudo netstat -an | grep -E "(6379|5432|5433)" | wc -l

# Monitor logs for errors
sudo tail -f /var/log/supervisor/supervisord.log
```

## Health Check Endpoint

```bash
# Check proxy health via HTTP
curl http://PROXY_VM_IP/health

# Expected response:
{
  "status": "healthy",
  "timestamp": "2025-08-26T10:30:00Z",
  "services": {
    "redis": "port 6379",
    "postgres_primary": "port 5432",
    "postgres_replica": "port 5433"
  }
}
```

## Maintenance Commands

### Restart All Services

```bash
sudo supervisorctl restart all
```

### Update Configurations

```bash
# After changing supervisor configs
sudo supervisorctl reread
sudo supervisorctl update
```

### View Real-time Connections

```bash
# Monitor active connections
watch 'sudo netstat -an | grep -E "(6379|5432|5433)"'
```

### Log Rotation Setup

```bash
# Add logrotate configuration
sudo tee /etc/logrotate.d/proxy-logs > /dev/null <<EOF
/var/log/*-proxy.*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        supervisorctl restart all
    endscript
}
EOF
```
