variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}

variable "network_name" {
  type = string
}

variable "subnetwork_self_link" {
  type = string
}

variable "machine_type" {
  type    = string
  default = "e2-micro"
}

variable "allowed_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "image" {
  type    = string
  default = "apache/apisix:3.18.0-debian"
}

variable "jwt_secret_id" {
  type = string
}

variable "endorsement_host" {
  type = string
}

variable "routing_host" {
  type = string
}

variable "web_host" {
  type = string
}
