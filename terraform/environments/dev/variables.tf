variable "project_id" {
  description = "Proyecto GCP donde se desplegará el reto."
  type        = string
}

variable "region" {
  description = "Región principal de los servicios."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Zona de Compute Engine utilizada por APISIX."
  type        = string
  default     = "us-central1-a"
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

variable "apisix_image" {
  description = "Imagen Docker utilizada para Apache APISIX."
  type        = string
  default     = "apache/apisix:3.18.0-debian"
}

variable "apisix_machine_type" {
  description = "Tipo de máquina para la VM que ejecuta APISIX."
  type        = string
  default     = "e2-micro"
}

variable "apisix_allowed_cidrs" {
  description = "Rangos permitidos para acceder al puerto público de APISIX."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
