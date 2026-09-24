output "external_ip" {
  value = google_compute_address.apisix.address
}

output "url" {
  value = "http://${google_compute_address.apisix.address}:9080"
}

output "service_account_email" {
  value = google_service_account.runtime.email
}
