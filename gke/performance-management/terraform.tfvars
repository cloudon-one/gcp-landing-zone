kubeconfig_path = "~/.kube/config"
cluster_name    = "gke-cluster"
project_id      = "gke-project"

performance_config = {
  enable_burst_scaling          = true
  enable_node_auto_provisioning = true
  load_testing_enabled          = true
  max_burst_capacity            = 50
} 