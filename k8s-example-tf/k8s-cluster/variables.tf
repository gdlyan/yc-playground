variable "folder_id" {
  description = "Yandex folder id from yc config list"
  type        = string
}

variable "default_user" {
  type        = string
  default     = "tutorial"
}

variable "private_key_file" {
  type        = string
  default     = "tutorial_id_rsa"
}

variable "network_id" {
  type = string
}

variable "subnet" {
  type = object({id = string, zone = string, v4_cidr_blocks = list(string)})
}
