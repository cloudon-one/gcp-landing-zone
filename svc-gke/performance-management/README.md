# Performance Management Module - Deployment Guide

## 📋 **Prerequisites**

### **Required Tools**

- ✅ Terraform >= 1.5
- ✅ kubectl
- ✅ gcloud CLI
- ✅ Access to GKE cluster

### **Cluster Requirements**

- ✅ GKE cluster running
- ✅ Cluster autoscaler enabled
- ✅ Node pools configured
- ✅ Network policies configured

## 🚀 **Step-by-Step Deployment Sequence**

### **Phase 1: Environment Setup**

#### **Step 1.1: Verify Prerequisites**

```bash
terraform version
kubectl cluster-info
gcloud config list
```

#### **Step 1.2: Navigate to Module Directory**

```bash
cd svc-gke/performance-management
```

### **Phase 2: Terraform Deployment**

#### **Step 2.1: Initialize Terraform**

```bash
terraform init
terraform providers
```

#### **Step 2.2: Validate Configuration**

```bash
terraform validate
terraform fmt -check
```

#### **Step 2.3: Plan Deployment**

```bash
terraform plan -out=deployment.tfplan
terraform show deployment.tfplan
```

#### **Step 2.4: Deploy Resources**

```bash
terraform apply deployment.tfplan
kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -20
```

### **Phase 3: Post-Deployment Verification**

#### **Step 3.1: Verify Core Resources**

```bash
kubectl get namespaces | grep -E "(production|monitoring|load-testing)"
kubectl get resourcequota --all-namespaces
kubectl get limitrange --all-namespaces
kubectl get priorityclass
```

#### **Step 3.2: Verify Autoscaling Configuration**

```bash
kubectl get hpa --all-namespaces
kubectl describe hpa app-hpa -n production
kubectl describe hpa api-hpa -n production
```

#### **Step 3.3: Verify Pod Disruption Budgets**

```bash
kubectl get pdb --all-namespaces
kubectl describe pdb app-pdb -n production
kubectl describe pdb api-pdb -n production
```

#### **Step 3.4: Verify Network Policies**

```bash
kubectl get networkpolicies --all-namespaces
kubectl describe networkpolicy performance-isolation -n production
```

### **Phase 4: Load Testing Setup**

#### **Step 4.1: Deploy Load Testing Resources**

```bash
terraform apply -target=kubernetes_namespace.load_testing
terraform apply -target=kubernetes_deployment.ab_load_test_runner
terraform apply -target=kubernetes_config_map.ab_load_test_scripts
```

#### **Step 4.2: Verify Load Testing Deployment**

```bash
kubectl get namespace load-testing
kubectl get deployment ab-load-test-runner -n load-testing
kubectl get pods -n load-testing -l app=ab-load-test-runner
kubectl get configmap ab-load-test-scripts -n load-testing
```

## 🧪 **Step-by-Step Testing Sequence**

### **Phase 5: Performance Testing**

#### **Step 5.1: Run Comprehensive Performance Tests**

```bash
./performance-test.sh
kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -10
```

#### **Step 5.2: Verify Test Results**

```bash
ls -la performance-test-report-*.txt
cat performance-test-report-$(date +%Y%m%d)*.txt
```

### **Phase 6: Load Testing Validation**

#### **Step 6.1: Manual Load Testing**

```bash
kubectl exec -it deployment/ab-load-test-runner -n load-testing -- /scripts/burst-test.sh
kubectl exec -it deployment/ab-load-test-runner -n load-testing -- /scripts/peak-test.sh
```

#### **Step 6.2: Monitor Load Testing**

```bash
kubectl get pods -n load-testing -w
kubectl logs deployment/ab-load-test-runner -n load-testing -f
```

### **Phase 7: Autoscaling Validation**

#### **Step 7.1: Test HPA Scaling**

```bash
kubectl get hpa --all-namespaces -w
kubectl describe hpa app-hpa -n production
kubectl describe hpa api-hpa -n production
```

#### **Step 7.2: Test Resource Quotas**

```bash
kubectl describe resourcequota production-quota -n production
kubectl run quota-test --image=nginx:alpine -n production --requests=cpu=10,memory=100Gi
```

## 🔍 **Validation Checklist**

### **Core Resources**

- [ ] Resource quotas created in all namespaces
- [ ] Limit ranges configured
- [ ] Priority classes defined
- [ ] Network policies applied

### **Autoscaling**

- [ ] HPA resources created
- [ ] HPA metrics configured
- [ ] Scaling policies defined
- [ ] Target deployments exist

### **Load Testing**

- [ ] Load testing namespace created
- [ ] Apache Bench deployment running
- [ ] Load testing scripts available
- [ ] Network policies allow external access

### **Performance**

- [ ] Performance tests pass
- [ ] Resource quotas enforced
- [ ] QoS classes working
- [ ] Autoscaling responsive

## 🚨 **Troubleshooting Commands**

### **Common Issues**

#### **Resource Creation Failures**

```bash
terraform state list
kubectl get all --all-namespaces
kubectl get events --all-namespaces --sort-by='.lastTimestamp'
```

#### **Load Testing Issues**

```bash
kubectl describe deployment ab-load-test-runner -n load-testing
kubectl logs deployment/ab-load-test-runner -n load-testing
kubectl get networkpolicies -n load-testing
```

#### **Autoscaling Issues**

```bash
kubectl describe hpa -n production
kubectl get apiservice v1beta1.metrics.k8s.io
kubectl top nodes
kubectl top pods --all-namespaces
```

## 📊 **Monitoring Commands**

### **Real-time Monitoring**

```bash
kubectl get all --all-namespaces -w
kubectl get hpa --all-namespaces -w
kubectl top pods --all-namespaces -w
```

### **Performance Metrics**

```bash
kubectl top nodes
kubectl top pods --all-namespaces
kubectl describe resourcequota --all-namespaces
kubectl get pods -o custom-columns=NAME:.metadata.name,QOS:.status.qosClass
```

## 🎯 **Success Criteria**

### **Deployment Success**

- ✅ All Terraform resources created successfully
- ✅ No errors in kubectl events
- ✅ All pods in Running state
- ✅ Services accessible

### **Testing Success**

- ✅ Performance tests complete without errors
- ✅ Load testing scripts execute successfully
- ✅ HPA responds to load changes
- ✅ Resource quotas enforced correctly

### **Operational Success**

- ✅ Autoscaling works as expected
- ✅ Load testing provides meaningful results
- ✅ Resource management prevents over-allocation
- ✅ Performance monitoring functional

