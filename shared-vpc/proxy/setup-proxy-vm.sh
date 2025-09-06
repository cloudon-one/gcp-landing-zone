#!/bin/bash

# Run this script on the proxy VM after it's created

# Update system
sudo apt-get update
sudo apt-get install -y socat supervisor nginx-light

# Create socat configuration directory
sudo mkdir -p /etc/socat

# Create Redis proxy configuration
sudo tee /etc/socat/redis.conf > /dev/null <<EOF
# Redis proxy configuration
REDIS_TARGET_IP=10.161.12.4
REDIS_TARGET_PORT=6378
REDIS_LISTEN_PORT=6379
EOF

# Create PostgreSQL proxy configuration  
sudo tee /etc/socat/postgresql.conf > /dev/null <<EOF
# PostgreSQL proxy configuration
POSTGRES_PRIMARY_IP=10.161.1.2
POSTGRES_REPLICA_IP=10.161.2.2
POSTGRES_PORT=5432
POSTGRES_PRIMARY_LISTEN_PORT=5432
POSTGRES_REPLICA_LISTEN_PORT=5433
EOF

# Create supervisor configuration for Redis proxy
sudo tee /etc/supervisor/conf.d/redis-proxy.conf > /dev/null <<EOF
[program:redis-proxy]
command=socat TCP-LISTEN:6379,fork,reuseaddr TCP:10.161.12.4:6378
autostart=true
autorestart=true
stderr_logfile=/var/log/redis-proxy.err.log
stdout_logfile=/var/log/redis-proxy.out.log
user=root
EOF

# Create supervisor configuration for PostgreSQL primary proxy
sudo tee /etc/supervisor/conf.d/postgres-primary-proxy.conf > /dev/null <<EOF
[program:postgres-primary-proxy]
command=socat TCP-LISTEN:5432,fork,reuseaddr TCP:10.161.1.2:5432
autostart=true
autorestart=true
stderr_logfile=/var/log/postgres-primary-proxy.err.log
stdout_logfile=/var/log/postgres-primary-proxy.out.log
user=root
EOF

# Create supervisor configuration for PostgreSQL replica proxy
sudo tee /etc/supervisor/conf.d/postgres-replica-proxy.conf > /dev/null <<EOF
[program:postgres-replica-proxy]
command=socat TCP-LISTEN:5433,fork,reuseaddr TCP:10.161.2.2:5432
autostart=true
autorestart=true
stderr_logfile=/var/log/postgres-replica-proxy.err.log
stdout_logfile=/var/log/postgres-replica-proxy.out.log
user=root
EOF

# Create health check endpoint
sudo tee /var/www/html/health > /dev/null <<EOF
{
  "status": "healthy",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "services": {
    "redis": "port 6379",
    "postgres_primary": "port 5432", 
    "postgres_replica": "port 5433"
  }
}
EOF

# Start services
sudo systemctl enable supervisor
sudo systemctl start supervisor
sudo systemctl enable nginx
sudo systemctl start nginx

# Reload supervisor to pick up new configurations
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start all

echo "Proxy services configured and started!"
echo "Services running:"
echo "- Redis proxy: port 6379 -> 10.161.12.4:6378"
echo "- PostgreSQL primary: port 5432 -> 10.161.1.2:5432"
echo "- PostgreSQL replica: port 5433 -> 10.161.2.2:5432"
echo "- Health check: http://VM_IP/health"
