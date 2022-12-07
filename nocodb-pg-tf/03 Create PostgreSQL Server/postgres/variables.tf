variable "default_user" {
  type        = string
  default     = "tutorial"
}

variable "private_key_file" {
  type        = string
  default     = "tutorial_id_rsa"
}

variable "postgres_password" {
  description = "Postgres password for default_user"
  type        = string  
}

variable "pgadmin_credentials" {
  type        =  object({email = string, password = string})  
}

variable "pg_private_ip_address" {
    type = string
    default = "10.130.0.101"
}

variable "subnet" {
  type = object({id = string, zone = string, v4_cidr_blocks = list(string)})
}

variable "pg_data_disk_size" {
 description = "max size of postgres database and pgadmin data disk"
 type        = number
 default     = 20
}

variable "recreate_data_disk" {
 description = "none - use existing disk; empty - create new empty disk; snapshot - create from snapshot with the name == variable value"
 type        = string
 default     = "none"
}