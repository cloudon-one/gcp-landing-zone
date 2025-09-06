billing_account_id = "123456-789012-345678"
folder_id          = "12345678901234567890"

labels = {
  environment = "production"
  team        = "devops"
  cost_center = "devops"
  owner       = "devops"
}

host_project_name = "host-project"

service_projects = {
  gke = {
    name = "gke-project"
    type = "gke" # connect to gke-vpc
    apis = []    # Uses default APIs for gke type
  }
  data = {
    name = "data-project"
    type = "data" # connect to data-vpc
    apis = []     # Uses default APIs for data type
  }
}