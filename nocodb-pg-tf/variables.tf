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

variable "postgres_password" {
  description = "Postgres password for default_user"
  type        = string  
}

variable "pgadmin_credentials" {
  type        =  object({email = string, password = string})  
}

variable "nocodb_database" {
  description = "Postgres database name for nocodb"
  type        = string  
  default     = "nocodb_database"
}

variable "web_front_subnets" {
 description = "Public subnets for instances that are directly exposed to web-traffic such as Load balancers, NAT, gateways, bastions etc."
 type =  list(object({zone = string, v4_cidr_blocks = list(string)}))
 default = [{"zone":"ru-central1-b", "v4_cidr_blocks" : ["10.129.0.0/24"]}]
}

variable "webapp_subnets" {
 description = "Isolated subnets for web applications frontend and backend"
 type =  list(object({zone = string, v4_cidr_blocks = list(string)}))
 default = [{"zone":"ru-central1-a", "v4_cidr_blocks" : ["10.130.0.0/24"]},
            {"zone":"ru-central1-b", "v4_cidr_blocks" : ["10.131.0.0/24"]},
            {"zone":"ru-central1-c", "v4_cidr_blocks" : ["10.132.0.0/24"]}]
}

variable "webapp_instances" {
 description = "contanerized webapp"
 type = list(object({ subnet_ix = number }))
 default = [{"subnet_ix" : 0}]
}

variable "ipsec_instances" {
 description = "VPN"
 type = list(object({ subnet_ix = number }))
 default = [{"subnet_ix" : 0}]
}

variable "pg_docker_instances" {
 description = "small postgres database - docker container"
 type = list(object({ subnet_ix = number }))
 default = [{"subnet_ix" : 0}]
}

variable "pg_data_disk_size" {
 description = "max size of postgres database and pgadmin data disk"
 type = number
 default = 20
}


variable "domain" {
  description = "domain name like example.com"
  default = "example.com"
} 
