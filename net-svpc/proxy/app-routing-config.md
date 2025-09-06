# Application Configuration Update Guide

## Step 1: Environment Variables in Deployments

```yaml
# deployment.yaml
env:
- name: REDIS_HOST
  value: "10.161.4.4"  # Proxy VM IP
- name: REDIS_PORT
  value: "6379"       # Proxy Redis port
- name: POSTGRES_PRIMARY_HOST
  value: "10.161.4.4"  # Proxy VM IP
- name: POSTGRES_PRIMARY_PORT
  value: "5432"       # Proxy PostgreSQL primary port
- name: POSTGRES_REPLICA_HOST
  value: "10.161.4.4"  # Proxy VM IP
- name: POSTGRES_REPLICA_PORT
  value: "5433"       # Proxy PostgreSQL replica port
```

## Step 2: Connection Strings

### Redis Connection Strings

```bash
redis://10.161.12.4:6378
```

### PostgreSQL Connection Strings

```bash
# Primary
postgresql://user:pass@10.161.4.4:5432/database

# Replica
postgresql://user:pass@10.161.4.4:5433/database
```

## Step 3: Update Application Code

### Node.js Example

```javascript

const redisClient = redis.createClient({
  host: '10.161.4.4',
  port: 6379
});

const pgPrimary = new Pool({
  host: '10.161.4.4',
  port: 5432,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME
});

const pgReplica = new Pool({
  host: '10.161.4.4',
  port: 5433,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME
});
```

### Python Example

```python

redis_client = redis.Redis(host='10.161.4.4', port=6379)

pg_primary = psycopg2.connect(
    host='10.161.4.4',
    port=5432,
    user=os.getenv('DB_USER'),
    password=os.getenv('DB_PASSWORD'),
    database=os.getenv('DB_NAME')
)

pg_replica = psycopg2.connect(
    host='10.161.4.4',
    port=5433,
    user=os.getenv('DB_USER'),
    password=os.getenv('DB_PASSWORD'),
    database=os.getenv('DB_NAME')
)
```

## Step 4: Test from GKE Pod

```bash
kubectl run test-pod --image=nicolaka/netshoot --rm -it -- /bin/bash

# Inside the pod, test connectivity
nc -zv 10.161.4.4 6379  # Redis
nc -zv 10.161.4.4 5432  # PostgreSQL Primary  
nc -zv 10.161.4.4 5433  # PostgreSQL Replica

redis-cli -h 10.161.4.4 -p 6379 ping
psql -h 10.161.4.4 -p 5432 -U your_user -d your_database -c "SELECT 1"
psql -h 10.161.4.4 -p 5433 -U your_user -d your_database -c "SELECT 1"
```

## Example Kubernetes Deployment 

```yaml
kubectl patch deployment app-name -p '{
  "spec": {
    "template": {
      "spec": {
        "containers": [{
          "name": "app-container-name",
          "env": [
            {"name": "REDIS_HOST", "value": "10.161.4.4"},
            {"name": "REDIS_PORT", "value": "6379"},
            {"name": "POSTGRES_PRIMARY_HOST", "value": "10.161.4.4"},
            {"name": "POSTGRES_PRIMARY_PORT", "value": "5432"},
            {"name": "POSTGRES_REPLICA_HOST", "value": "10.161.4.4"},
            {"name": "POSTGRES_REPLICA_PORT", "value": "5433"}
          ]
        }]
      }
    }
  }
}
```
