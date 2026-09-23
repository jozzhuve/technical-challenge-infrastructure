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
