organization_id = ""
host_project_id = "host-project"
gke_project_id  = "gke-project"
data_project_id = "data-project"

devops_team_members = [
  "user:devops1@example.com"
]

backend_team_members = [
  "group:backend@example.com"
]

frontend_team_members = [
  "group:frontend@example.com"
]

mobile_team_members = [
  "group:mobile@example.com"
]

service_accounts = [
  "serviceAccount:bastion@host-project.iam.gserviceaccount.com",
  "serviceAccount:gke-service-account@gke-project.iam.gserviceaccount.com",
  "serviceAccount:cloudsql-admin@data-project.iam.gserviceaccount.com"
]

gke_workload_identity_service_accounts = [
  "serviceAccount:gke-project.svc.id.goog[backend/backend-sa]",
  "serviceAccount:gke-project.svc.id.goog[frontend/frontend-sa]",
  "serviceAccount:gke-project.svc.id.goog[api/api-sa]",
  "serviceAccount:gke-project.svc.id.goog[workers/workers-sa]",
  "serviceAccount:gke-project.svc.id.goog[monitoring/monitoring-sa]"
]

iap_tunnel_users = [
  "user:devops1@example.com"
]

restricted_services     = []
bridge_services         = []
vpc_restricted_services = []


