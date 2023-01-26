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
}

variable "local_public_ip" {
    type = string
}

variable "local_subnet" {
    type = string
}

variable "psk" {
    type = string
    default = "BlaBlaPSK"
}

variable "ipsec_conf_local_dir" {
    type = string
}