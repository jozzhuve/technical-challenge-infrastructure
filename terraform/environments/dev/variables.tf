variable "project_id" {
  description = "Proyecto GCP donde se desplegará el reto."
  type        = string
}

variable "region" {
  description = "Región principal de los servicios."
  type        = string
  default     = "us-central1"
}

variable "endorsement_image" {
  description = "Imagen OCI del servicio de endosos."
  type        = string
}

variable "routing_image" {
  description = "Imagen OCI del servicio de rutas."
  type        = string
}

variable "web_image" {
  description = "Imagen OCI del frontend."
  type        = string
}
