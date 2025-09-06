# Network Policies Deployment Guide

This guide provides step-by-step instructions for deploying network policies to the fintech GKE cluster.

## Prerequisites

1. **GKE Cluster Access**: Ensure you have access to the GKE cluster
2. **Terraform**: Version >= 1.5 installed
3. **kubectl**: Configured to access the cluster
4. **Google Cloud SDK**: Authenticated with appropriate permissions
5. **Network Policy Enabled**: GKE cluster must have network policies enabled

## Pre-Deployment Checklist

- [ ] GKE cluster has network policies enabled
- [ ] Terraform is installed and configured
- [ ] kubectl is configured for the cluster
- [ ] Google Cloud authentication is set up
- [ ] Required namespaces exist or will be created
- [ ] Application pods have proper labels

## Step 1: Enable Network Policies in GKE

If network policies are not already enabled, update the GKE configuration:

```bash
cd ../
terraform plan
terraform apply
```

## Step 2: Prepare Network Policies

```bash
cd network-policies
./validate-terraform.sh
cat validation-report-*.txt
```

## Step 3: Create Required Namespaces

Ensure the required namespaces exist:

```bash
kubectl create namespace backend --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace frontend --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace api --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace workers --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace mobile --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace database --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -
```

## Step 4: Deploy Network Policies

```bash
terraform init
terraform plan -out=network-policies.tfplan
terraform show network-policies.tfplan
terraform apply network-policies.tfplan
```

## Step 5: Verify Deployment

```bash
kubectl get networkpolicies --all-namespaces
kubectl get networkpolicies -n backend
kubectl get networkpolicies -n frontend
kubectl get networkpolicies -n api
kubectl get networkpolicies -n monitoring
kubectl describe networkpolicies --all-namespaces
```

## Step 6: Test Network Policies

```bash
./test-network-policies.sh
./test-network-policies.sh --cleanup
echo "Network policy tests completed"
```

## Step 7: Monitor and Validate

```bash
kubectl get events --all-namespaces | grep NetworkPolicy
kubectl logs -n kube-system -l k8s-app=calico-node --tail=50
```

## Rollback Plan

If issues occur, you can rollback the network policies:

```bash
kubectl delete networkpolicies --all --all-namespaces
terraform destroy
kubectl get networkpolicies --all-namespaces
```

## Troubleshooting

### Common Issues

1. **DNS Resolution Failing**

   ```bash
   # Check DNS network policy
   kubectl get networkpolicies -n kube-system
   
   # Test DNS from a pod
   kubectl exec -it <pod-name> -n <namespace> -- nslookup kubernetes.default.svc.cluster.local
   ```

2. **Expected Connectivity Not Working**
   - Verify network policies are applied to correct namespaces
   - Check pod labels match network policy selectors
   - Ensure target services are running
   - For database access, verify Cloud SQL and Memorystore private IP ranges are correct

3. **Unexpected Connectivity Working**
   - Verify default deny policies are applied
   - Check for conflicting network policies
   - Ensure network policy addon is enabled
   - For database access, verify IP-based egress policies are correctly configured

### Debugging Commands

```bash
kubectl get networkpolicies --all-namespaces -o wide
kubectl exec -it <pod-name> -n <namespace> -- ip route
kubectl logs -n kube-system -l k8s-app=calico-node --tail=100
kubectl get events --all-namespaces | grep -i network
```

## Post-Deployment Checklist

- [ ] All network policies are deployed successfully
- [ ] DNS resolution works in all namespaces
- [ ] Application connectivity is working as expected
- [ ] Security tests pass (unauthorized access is blocked)
- [ ] Monitoring and logging are functioning
- [ ] No policy violations are reported
- [ ] Application performance is not degraded

## Monitoring and Maintenance

### Regular Checks

1. **Weekly**: Review network policy violations
2. **Monthly**: Update network policies based on application changes
3. **Quarterly**: Review and optimize network policy rules

### Monitoring Commands

```bash
kubectl get networkpolicies --all-namespaces -o wide
kubectl logs -n kube-system -l k8s-app=calico-node --tail=50
kubectl get events --all-namespaces | grep NetworkPolicy
```

## Security Considerations

1. **Principle of Least Privilege**: Only allow necessary communication paths
2. **Default Deny**: All traffic is denied by default
3. **Regular Review**: Review network policies regularly
4. **Monitoring**: Monitor for policy violations and connectivity issues
5. **Documentation**: Keep network policies well-documented

## Support

For issues or questions:

1. Check the troubleshooting section
2. Review the network policy documentation
3. Contact the DevOps team
4. Check cluster logs for detailed error information

## References

- [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [GKE Network Policy](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy)
- [Calico Network Policy](https://docs.projectcalico.org/security/network-policy) 