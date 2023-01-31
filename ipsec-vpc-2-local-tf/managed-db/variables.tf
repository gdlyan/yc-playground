variable "network_id" {
  type    = string
}

variable "sg_mdb_id" {
  type = string
}

variable "subnets" {
  type    = list(object({id = string, zone = string, v4_cidr_blocks = list(string)}))
}

variable "dbname" {
  type    = string
}

variable "dbuser" {
  type    = string
}

variable "sqlpassword" {
  type    = string
  default = "random"
}

resource "random_string" "sqlpassword" {
  length  = 20
  special = false
  upper   = true
}

locals {
  sqlpassword = var.sqlpassword == "random" ? random_string.sqlpassword.result : var.sqlpassword
}

