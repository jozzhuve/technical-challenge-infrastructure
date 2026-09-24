variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "name" {
  type = string
}

variable "image" {
  type = string
}

variable "port" {
  type = number
}

variable "ingress" {
  type    = string
  default = "INGRESS_TRAFFIC_ALL"

  validation {
    condition = contains([
      "INGRESS_TRAFFIC_ALL",
      "INGRESS_TRAFFIC_INTERNAL_ONLY",
      "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
    ], var.ingress)
    error_message = "El valor de ingress no es válido para Cloud Run v2."
  }
}

variable "environment" {
  type    = map(string)
  default = {}
}

variable "secret_environment" {
  type = map(object({
    secret  = string
    version = optional(string, "latest")
  }))
  default = {}
}

variable "allow_unauthenticated" {
  type    = bool
  default = false
}

variable "cloud_sql_connection_name" {
  type     = string
  default  = null
  nullable = true
}
