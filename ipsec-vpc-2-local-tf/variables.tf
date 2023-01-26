variable "token" {
  description = "echo $TF_VAR_token (env varriable should be exported in advance) or set in terraform.tfvars"
  type        = string
}

variable "cloud_id" {
  description = "Yandex cloud id from yc config list"
  type        = string
}

variable "folder_id" {
  description = "Yandex folder id from yc config list"
  type        = string
}

variable "local_public_ip" {
  description = "Public IP of a local machine, could be result of $ curl ifconfig.co"
  type        = string
}

variable "local_subnet" {
  description = "Subnet on the local side of a tunnel"
  type        = string
}

variable "project_dir" {
  type        = string
  default     = "null"    
}

locals {
  ipsec_conf_local_dir = var.project_dir == "null" ? "${abspath(path.module)}/ipsec-config/local" : "${var.project_dir}/ipsec-config/local"
}