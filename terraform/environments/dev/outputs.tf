output "artifact_registry" {
  value = google_artifact_registry_repository.containers.name
}

output "endorsement_url" {
  value = module.endorsement.url
}

output "routing_url" {
  value = module.routing.url
}

output "web_url" {
  value = module.web.url
}

output "database_connection_name" {
  value = google_sql_database_instance.endorsement.connection_name
}
