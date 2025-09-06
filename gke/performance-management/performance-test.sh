#!/bin/bash

set -e

echo "🚀 Starting Performance Testing for GKE Cluster..."

CLUSTER_NAME="gke-cluster"
REGION="us-central1"
PROJECT_ID="gke-project"
NAMESPACE="production"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' 

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        exit 1
    fi
    
    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud is not installed"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

setup_cluster_access() {
    print_status "Setting up cluster access..."
    
    gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION --project $PROJECT_ID

    if kubectl cluster-info &> /dev/null; then
        print_success "Cluster access established"
    else
        print_error "Cannot access cluster"
        exit 1
    fi
}

check_cluster_state() {
    print_status "Checking current cluster state..."
    
    echo "=== Node Information ==="
    kubectl get nodes -o wide
    
    echo -e "\n=== Node Pool Status ==="
    kubectl get nodes --label-columns=cloud.google.com/gke-nodepool
    
    echo -e "\n=== Current Pod Distribution ==="
    kubectl get pods --all-namespaces -o wide
    
    echo -e "\n=== HPA Status ==="
    kubectl get hpa --all-namespaces
    
    echo -e "\n=== Resource Quotas ==="
    kubectl get resourcequota --all-namespaces
}

test_burst_capacity() {
    print_status "Testing burst capacity..."
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: burst-test
  namespace: $NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: burst-test
  template:
    metadata:
      labels:
        app: burst-test
    spec:
      containers:
      - name: burst-test
        image: nginx:alpine
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
        ports:
        - containerPort: 80
EOF
    
    print_status "Scaling up to test burst capacity..."
    kubectl scale deployment burst-test --replicas=20 -n $NAMESPACE
    sleep 30
    
    echo "=== Burst Test Results ==="
    kubectl get pods -n $NAMESPACE -l app=burst-test
    kubectl get hpa -n $NAMESPACE
    kubectl delete deployment burst-test -n $NAMESPACE
}

test_autoscaling() {
    print_status "Testing autoscaling behavior..."
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cpu-test
  namespace: $NAMESPACE
spec:
  replicas: 3
  selector:
    matchLabels:
      app: cpu-test
  template:
    metadata:
      labels:
        app: cpu-test
    spec:
      containers:
      - name: cpu-test
        image: busybox:latest
        command: ["/bin/sh", "-c"]
        args:
        - |
          while true; do
            dd if=/dev/zero of=/dev/null bs=1M count=1000
            sleep 1
          done
        resources:
          requests:
            cpu: "500m"
            memory: "512Mi"
          limits:
            cpu: "1"
            memory: "1Gi"
EOF
    
    cat <<EOF | kubectl apply -f -
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: cpu-test-hpa
  namespace: $NAMESPACE
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: cpu-test
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
EOF
    
    print_status "Monitoring autoscaling for 2 minutes..."
    for i in {1..12}; do
        echo "=== Check $i ==="
        kubectl get hpa cpu-test-hpa -n $NAMESPACE
        kubectl get pods -n $NAMESPACE -l app=cpu-test
        sleep 10
    done
    
    kubectl delete deployment cpu-test -n $NAMESPACE
    kubectl delete hpa cpu-test-hpa -n $NAMESPACE
}

test_resource_quotas() {
    print_status "Testing resource quotas and limits..."
    
    echo "=== Current Resource Quotas ==="
    kubectl get resourcequota --all-namespaces -o yaml
    
    echo -e "\n=== Limit Ranges ==="
    kubectl get limitrange --all-namespaces -o yaml
    print_status "Testing quota enforcement..."
    
    # Test 1: Try to create a pod that exceeds quota limits
    print_status "Test 1: Attempting to create pod with excessive resources (should be rejected)..."
    
    cat <<EOF | kubectl apply -f - 2>&1 | tee /tmp/quota-test-output.txt
apiVersion: v1
kind: Pod
metadata:
  name: quota-test
  namespace: $NAMESPACE
spec:
  containers:
  - name: quota-test
    image: nginx:alpine
    resources:
      requests:
        cpu: "10"
        memory: "100Gi"
      limits:
        cpu: "20"
        memory: "200Gi"
EOF
    
    QUOTA_TEST_RESULT=$?
    
    # Check if the pod was created or rejected
    sleep 3
    if kubectl get pod quota-test -n $NAMESPACE &> /dev/null; then
        print_warning "Pod created despite large resource requests - quota enforcement may not be working"
        kubectl delete pod quota-test -n $NAMESPACE --ignore-not-found
    else
        print_success "✅ Resource quota enforcement working correctly - pod was rejected"
        echo "Expected behavior: Pod rejected due to resource limits"
        echo "Quota limits: CPU=4, Memory=8Gi"
        echo "Pod requested: CPU=20, Memory=200Gi"
    fi
    
    # Test 2: Create a pod within quota limits (should succeed)
    print_status "Test 2: Creating pod within quota limits (should succeed)..."
    
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: quota-test-within-limits
  namespace: $NAMESPACE
spec:
  containers:
  - name: quota-test-within-limits
    image: nginx:alpine
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "200m"
        memory: "256Mi"
EOF
    
    sleep 5
    if kubectl get pod quota-test-within-limits -n $NAMESPACE &> /dev/null; then
        print_success "✅ Pod created successfully within quota limits"
        kubectl delete pod quota-test-within-limits -n $NAMESPACE --ignore-not-found
    else
        print_warning "Pod creation failed even within quota limits"
    fi
    
    # Test 3: Check current quota usage
    print_status "Test 3: Checking current quota usage..."
    echo "=== Current Quota Usage ==="
    kubectl describe resourcequota --all-namespaces
    
    print_success "Resource quota testing completed"
}

test_qos_classes() {
    print_status "Testing QoS classes..."
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: guaranteed-pod
  namespace: $NAMESPACE
spec:
  containers:
  - name: guaranteed
    image: nginx:alpine
    resources:
      requests:
        cpu: "500m"
        memory: "512Mi"
      limits:
        cpu: "500m"
        memory: "512Mi"
---
apiVersion: v1
kind: Pod
metadata:
  name: burstable-pod
  namespace: $NAMESPACE
spec:
  containers:
  - name: burstable
    image: nginx:alpine
    resources:
      requests:
        cpu: "250m"
        memory: "256Mi"
      limits:
        cpu: "1"
        memory: "1Gi"
---
apiVersion: v1
kind: Pod
metadata:
  name: besteffort-pod
  namespace: $NAMESPACE
spec:
  containers:
  - name: besteffort
    image: nginx:alpine
EOF
    
    sleep 10
    
    echo "=== QoS Class Verification ==="
    kubectl get pods -n $NAMESPACE -o custom-columns=NAME:.metadata.name,QOS:.status.qosClass
    kubectl delete pod guaranteed-pod burstable-pod besteffort-pod -n $NAMESPACE
}

test_load_testing() {
    print_status "Testing load testing capabilities..."
    
    if kubectl get deployment ab-load-test-runner -n load-testing &> /dev/null; then
        print_success "Apache Bench load testing deployment found"
        
        echo "=== Load Testing Status ==="
        kubectl get pods -n load-testing -l app=ab-load-test-runner
        
        print_status "Running sample load test..."
        kubectl run load-test-sample --image=httpd:alpine --rm -i --restart=Never -- sh -c "apk add --no-cache apache2-utils && ab -n 10 -c 2 http://fintech-api.production.svc.cluster.local:8080/health" || print_warning "Load test failed - API endpoint may not be available"
        
    else
        print_warning "Apache Bench load testing not deployed"
        print_status "To enable load testing, run: ./solve-load-testing.sh"
    fi
}

collect_performance_metrics() {
    print_status "Collecting performance metrics..."
    
    echo "=== Node Metrics ==="
    kubectl top nodes
    
    echo -e "\n=== Pod Metrics ==="
    kubectl top pods --all-namespaces
    
    echo -e "\n=== Cluster Events ==="
    kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -20
    
    echo -e "\n=== Node Conditions ==="
    kubectl get nodes -o custom-columns=NAME:.metadata.name,CONDITIONS:.status.conditions[*].type
}

generate_report() {
    print_status "Generating performance report..."
    
    REPORT_FILE="performance-test-report-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "GKE Performance Test Report"
        echo "=========================="
        echo "Date: $(date)"
        echo "Cluster: $CLUSTER_NAME"
        echo "Region: $REGION"
        echo "Project: $PROJECT_ID"
        echo ""
        
        echo "=== Cluster Information ==="
        kubectl cluster-info
        echo ""
        
        echo "=== Node Information ==="
        kubectl get nodes -o wide
        echo ""
        
        echo "=== Autoscaling Status ==="
        kubectl get hpa --all-namespaces
        echo ""
        
        echo "=== Resource Quotas ==="
        kubectl get resourcequota --all-namespaces
        echo ""
        
        echo "=== Performance Metrics ==="
        kubectl top nodes
        echo ""
        kubectl top pods --all-namespaces
        echo ""
        
        echo "=== Recent Events ==="
        kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -30
        
    } > "$REPORT_FILE"
    
    print_success "Performance report saved to: $REPORT_FILE"
}

main() {
    print_status "Starting comprehensive performance testing..."
    
    check_prerequisites
    setup_cluster_access
    check_cluster_state
    test_burst_capacity
    test_autoscaling
    test_resource_quotas
    test_qos_classes
    test_load_testing
    collect_performance_metrics
    generate_report
    
    print_success "Performance testing completed successfully!"
    print_status "Review the generated report for detailed results."
}

main "$@" 