#!/bin/bash

# Run this on the proxy VM to add Redis read endpoint support

echo "Updating Redis proxy configuration..."

# Stop current Redis proxy
sudo supervisorctl stop redis-proxy

# Create configuration for Redis primary (write) proxy
sudo tee /etc/supervisor/conf.d/redis-primary-proxy.conf > /dev/null <<EOF
[program:redis-primary-proxy]
command=socat TCP-LISTEN:6379,fork,reuseaddr TCP:10.161.12.4:6378
autostart=true
autorestart=true
stderr_logfile=/var/log/redis-primary-proxy.err.log
stdout_logfile=/var/log/redis-primary-proxy.out.log
user=root
EOF

# Create configuration for Redis read proxy  
sudo tee /etc/supervisor/conf.d/redis-read-proxy.conf > /dev/null <<EOF
[program:redis-read-proxy]
command=socat TCP-LISTEN:6380,fork,reuseaddr TCP:10.161.12.5:6378
autostart=true
autorestart=true
stderr_logfile=/var/log/redis-read-proxy.err.log
stdout_logfile=/var/log/redis-read-proxy.out.log
user=root
EOF

# Remove old Redis proxy config
sudo rm -f /etc/supervisor/conf.d/redis-proxy.conf

# Update health check
sudo tee /var/www/html/health > /dev/null <<EOF
{
  "status": "healthy",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "services": {
    "redis_primary": "port 6379",
    "redis_read": "port 6380",
    "postgres_primary": "port 5432",
    "postgres_replica": "port 5433"
  }
}
EOF

# Reload supervisor and start new services
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start redis-primary-proxy
sudo supervisorctl start redis-read-proxy

# Test both Redis endpoints
echo ""
echo "Testing Redis endpoints..."
echo "Testing Redis primary (10.161.12.4:6378 -> localhost:6379)..."
nc -zv 10.161.12.4 6378
nc -zv localhost 6379

echo "Testing Redis read (10.161.12.5:6378 -> localhost:6380)..."
nc -zv 10.161.12.5 6378  
nc -zv localhost 6380

echo ""
echo "Updated Redis proxy configuration:"
echo "- Redis Primary: localhost:6379 -> 10.161.12.4:6378"
echo "- Redis Read: localhost:6380 -> 10.161.12.5:6378"
echo "- PostgreSQL Primary: localhost:5432 -> 10.161.1.2:5432"
echo "- PostgreSQL Replica: localhost:5433 -> 10.161.2.3:5432"

echo ""
echo "Checking all services status:"
sudo supervisorctl status
