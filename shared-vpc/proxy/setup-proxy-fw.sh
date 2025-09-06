#!/bin/bash

PROJECT_ID="host-project"

gcloud compute firewall-rules update allow-gke-to-proxy \
    --project=$PROJECT_ID \
    --rules=tcp:5432,tcp:6379,tcp:5433,tcp:6380 \
    --description="Allow GKE pods to reach database proxy (PostgreSQL + Redis)"

gcloud compute firewall-rules create allow-proxy-to-services \
    --project=$PROJECT_ID \
    --direction=EGRESS \
    --priority=1000 \
    --network=data-vpc \
    --action=ALLOW \
    --rules=tcp:5432,tcp:6379 \
    --destination-ranges=10.161.1.0/24,10.161.2.0/24,10.161.12.0/28 \
    --target-tags=database-proxy \
    --description="Allow proxy to reach private PostgreSQL and Redis"

echo "Firewall rules created successfully!"
