resource "google_service_account" "runtime" {
  project      = var.project_id
  account_id   = "apisix-gateway-runtime"
  display_name = "Runtime Apache APISIX"
}

resource "google_secret_manager_secret_iam_member" "jwt" {
  project   = var.project_id
  secret_id = var.jwt_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.runtime.email}"
}

resource "google_compute_address" "apisix" {
  project = var.project_id
  name    = "apisix-gateway-ip"
  region  = var.region
}

resource "google_compute_firewall" "apisix" {
  project = var.project_id
  name    = "allow-apisix-gateway"
  network = var.network_name

  direction     = "INGRESS"
  source_ranges = var.allowed_cidrs
  target_tags   = ["apisix-gateway"]

  allow {
    protocol = "tcp"
    ports    = ["9080"]
  }
}

resource "google_compute_instance" "apisix" {
  depends_on = [google_secret_manager_secret_iam_member.jwt]

  project      = var.project_id
  name         = "apisix-gateway"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["apisix-gateway"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = var.subnetwork_self_link

    access_config {
      nat_ip = google_compute_address.apisix.address
    }
  }

  service_account {
    email  = google_service_account.runtime.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = templatefile("${path.module}/startup.sh.tftpl", {
    project_id       = var.project_id
    apisix_image     = var.image
    jwt_secret_id    = var.jwt_secret_id
    endorsement_host = var.endorsement_host
    routing_host     = var.routing_host
    web_host         = var.web_host
  })

  labels = {
    component = "apisix"
    purpose   = "technical-challenge"
  }
}
