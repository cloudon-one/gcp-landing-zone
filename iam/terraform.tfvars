region                                 = "us-central1"
enable_sql_iam                         = true
gke_workload_identity_service_accounts = {}
enable_os_login_iam                    = true

os_login_users = [
  "user:devops@example.com"
]

enable_bastion_iam    = true
enable_iap_tunnel_iam = true

iap_tunnel_users = [
  "user:devops@example.com",

] 