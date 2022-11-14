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

variable "default_user" {
  type        = string
  default     = "ubuntu"
}

variable "private_key_file" {
  type        = string
  default     = "id_rsa"
}

variable "nat_instance_vpc_name" {
 type = string
 default = "nat-instance-vpc-tf"
}

