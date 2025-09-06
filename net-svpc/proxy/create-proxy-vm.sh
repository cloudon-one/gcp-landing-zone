#!/bin/bash

PROJECT_ID="host-project"
ZONE="us-central1-a"
SUBNET_NAME="data-subnet"
VM_NAME="database-proxy"

gcloud compute instances create $VM_NAME \
    --project=$PROJECT_ID \
    --zone=$ZONE \
    --machine-type=e2-standard-2 \
    --network-interface=subnet=projects/$PROJECT_ID/regions/us-central1/subnetworks/$SUBNET_NAME,no-address \
    --image-family=ubuntu-2204-lts \
    --image-project=ubuntu-os-cloud \
    --boot-disk-size=20GB \
    --boot-disk-type=pd-standard \
    --tags=database-proxy,allow-internal \
    --metadata=startup-script='#!/bin/bash
apt-get update
apt-get install -y socat nginx-light
systemctl enable socat-proxy
systemctl enable nginx
' \
    --service-account=default \
    --scopes=https://www.googleapis.com/auth/cloud-platform

echo "Proxy VM created successfully!"
echo "VM Name: $VM_NAME"
echo "Zone: $ZONE"
echo "Project: $PROJECT_ID"
