variable "default_user" {
  type        = string
  default     = "tutorial"
}

variable "private_key_file" {
  type        = string
  default     = "tutorial_id_rsa"
}

variable "ipsec_instance_public_ip" {
    type = string
}

variable "cloud_subnet" {
    type = string
    default = "10.128.0.0/9"
}

variable "local_public_ip" {
    type = string
}

variable "local_subnet" {
    type = string
}

variable "psk" {
    type = string
}

variable "ipsec_conf_local_dir" {
    type = string
}