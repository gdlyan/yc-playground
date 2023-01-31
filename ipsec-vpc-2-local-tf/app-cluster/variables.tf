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

variable "conn_string" {
  type = string
}
variable "subnet_ids" {
  description = "Subnets for nocobd instances"  
  type        =  list(string)
}

variable "zones" {
  description = "List of zones for nocodb instances"  
  type        =  list(string)
}

variable nlb_subnet {
  description = "home subnet for network load balancer"  
  type = object({id = string, zone = string, v4_cidr_blocks = list(string)})
}

variable "sg_app_id" {
  description = "security group for app"
  type = string
}
