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

variable "pg_instance_private_ip" {
  description = "Private IP address on the PostgreSQL Server" 
  type        = string
}

variable "postgres_password" {
  description = "Postgres password for default_user"
  type        = string  
}

variable "nocodb_database" {
  description = "Schema name for nocodb database on the PostgreSQL Server" 
  type        = string
  default     = "nocodb"
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
