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

variable "nlb_instance_private_ip" {
  description = "Private IP address on the webapp network load balancer" 
  type        = string
}

variable "domain" {
  description = "Second level domain, for example johnsmith.jq"
  type        = string
}

variable "subdomain" {
  description = "Third level domain"
  type        = string
  default     = "nocodb"
}

variable proxy_subnet {
  description = "home subnet for nginx proxy"  
  type = object({id = string, zone = string, v4_cidr_blocks = list(string)})
}