locals {
  services = toset([
    "artifactregistry.googleapis.com",
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

module "endorsement" {
  source     = "../../modules/cloud-run"
  depends_on = [google_project_service.required]

  project_id                = var.project_id
  region                    = var.region
  name                      = "endorsement-service"
  image                     = var.endorsement_image
  port                      = 8080
  allow_unauthenticated     = true
  cloud_sql_connection_name = google_sql_database_instance.endorsement.connection_name
  environment = {
    NODE_ENV          = "production"
    PORT              = "8080"
    HOST              = "0.0.0.0"
    LOG_LEVEL         = "info"
    DATABASE_HOST     = "/cloudsql/${google_sql_database_instance.endorsement.connection_name}"
    DATABASE_PORT     = "5432"
    DATABASE_NAME     = google_sql_database.endorsement.name
    DATABASE_USER     = google_sql_user.endorsement.name
    DATABASE_PASSWORD = random_password.database.result
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
  allow_unauthenticated = true
}
