region       = "us-central1"
project_id   = "gke-project"
cluster_name = "gke-cluster"

# kubeconfig_path = "~/.kube/config"

pod_security_standards_config = {
  mode    = "ENFORCED"
  version = "v1.32"
}