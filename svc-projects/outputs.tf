output "host_project_id" {
  description = "The ID of the host project"
  value       = module.service_projects.host_project.project_id
}

output "host_project_details" {
  description = "Host project details"
  value       = module.service_projects.host_project
}

output "service_projects" {
  description = "All service projects details"
  value       = module.service_projects.service_projects
}

output "service_project_ids" {
  description = "Map of service project IDs"
  value       = module.service_projects.service_project_ids
}

output "gke_project_id" {
  description = "The ID of the GKE service project (legacy)"
  value       = module.service_projects.gke_project_id
}

output "data_project_id" {
  description = "The ID of the Data service project (legacy)"
  value       = module.service_projects.data_project_id
}

output "gke_project_details" {
  description = "GKE project details (legacy)"
  value       = module.service_projects.gke_project
}

output "data_project_details" {
  description = "Data project details (legacy)"
  value       = module.service_projects.data_project
}