locals {
  services = toset([
    "artifactregistry.googleapis.com",
    "compute.googleapis.com",
    "run.googleapis.com",
    "sqladmin.googleapis.com",
    "secretmanager.googleapis.com"
  ])
}

resource "google_project_service" "required" {
  for_each           = local.services
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_compute_network" "challenge" {
  depends_on              = [google_project_service.required]
  project                 = var.project_id
  name                    = "technical-challenge-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "challenge" {
  project                  = var.project_id
  name                     = "technical-challenge-subnet"
  region                   = var.region
  network                  = google_compute_network.challenge.id
  ip_cidr_range            = "10.20.0.0/24"
  private_ip_google_access = true
}

resource "google_artifact_registry_repository" "containers" {
  depends_on    = [google_project_service.required]
  project       = var.project_id
  location      = var.region
  repository_id = "technical-challenge"
  format        = "DOCKER"
  description   = "Imágenes del reto técnico"
}

resource "random_password" "database" {
  length  = 24
  special = true
}

resource "random_password" "apisix_jwt" {
  length  = 48
  special = false
}

resource "google_secret_manager_secret" "database_password" {
  depends_on = [google_project_service.required]
  project    = var.project_id
  secret_id  = "endorsement-database-password"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "database_password" {
  secret      = google_secret_manager_secret.database_password.id
  secret_data = random_password.database.result
}

resource "google_secret_manager_secret" "apisix_jwt" {
  depends_on = [google_project_service.required]
  project    = var.project_id
  secret_id  = "apisix-jwt-secret"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "apisix_jwt" {
  secret      = google_secret_manager_secret.apisix_jwt.id
  secret_data = random_password.apisix_jwt.result
}

resource "google_sql_database_instance" "endorsement" {
  depends_on          = [google_project_service.required]
  project             = var.project_id
  name                = "endorsement-db"
  region              = var.region
  database_version    = "POSTGRES_16"
  deletion_protection = false

  settings {
    tier              = "db-f1-micro"
    availability_type = "ZONAL"
    disk_type         = "PD_SSD"
    disk_size         = 10

    backup_configuration {
      enabled = true
    }
  }
}

resource "google_sql_database" "endorsement" {
  project  = var.project_id
  name     = "endorsement"
  instance = google_sql_database_instance.endorsement.name
}

resource "google_sql_user" "endorsement" {
  project  = var.project_id
  name     = "endorsement"
  instance = google_sql_database_instance.endorsement.name
  password = random_password.database.result
}

module "endorsement" {
  source     = "../../modules/cloud-run"
  depends_on = [google_project_service.required, google_secret_manager_secret_version.database_password]

  project_id                = var.project_id
  region                    = var.region
  name                      = "endorsement-service"
  image                     = var.endorsement_image
  port                      = 8080
  ingress                   = "INGRESS_TRAFFIC_INTERNAL_ONLY"
  allow_unauthenticated     = true
  cloud_sql_connection_name = google_sql_database_instance.endorsement.connection_name

  environment = {
    NODE_ENV      = "production"
    PORT          = "8080"
    HOST          = "0.0.0.0"
    LOG_LEVEL     = "info"
    DATABASE_HOST = "/cloudsql/${google_sql_database_instance.endorsement.connection_name}"
    DATABASE_PORT = "5432"
    DATABASE_NAME = google_sql_database.endorsement.name
    DATABASE_USER = google_sql_user.endorsement.name
  }

  secret_environment = {
    DATABASE_PASSWORD = {
      secret  = google_secret_manager_secret.database_password.secret_id
      version = "latest"
    }
  }
}

resource "google_project_iam_member" "endorsement_cloud_sql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${module.endorsement.service_account_email}"
}

module "routing" {
  source     = "../../modules/cloud-run"
  depends_on = [google_project_service.required]

  project_id            = var.project_id
  region                = var.region
  name                  = "routing-service"
  image                 = var.routing_image
  port                  = 8081
  ingress               = "INGRESS_TRAFFIC_INTERNAL_ONLY"
  allow_unauthenticated = true

  environment = {
    PORT = "8081"
  }
}

module "web" {
  source     = "../../modules/cloud-run"
  depends_on = [google_project_service.required]

  project_id            = var.project_id
  region                = var.region
  name                  = "technical-challenge-web"
  image                 = var.web_image
  port                  = 80
  ingress               = "INGRESS_TRAFFIC_INTERNAL_ONLY"
  allow_unauthenticated = true
}

module "apisix" {
  source = "../../modules/apisix-gce"

  depends_on = [
    google_project_service.required,
    google_secret_manager_secret_version.apisix_jwt,
    module.endorsement,
    module.routing,
    module.web
  ]

  project_id           = var.project_id
  region               = var.region
  zone                 = var.zone
  network_name         = google_compute_network.challenge.name
  subnetwork_self_link = google_compute_subnetwork.challenge.self_link
  machine_type         = var.apisix_machine_type
  allowed_cidrs        = var.apisix_allowed_cidrs
  image                = var.apisix_image
  jwt_secret_id        = google_secret_manager_secret.apisix_jwt.secret_id
  endorsement_host     = trimprefix(module.endorsement.url, "https://")
  routing_host         = trimprefix(module.routing.url, "https://")
  web_host             = trimprefix(module.web.url, "https://")
}
