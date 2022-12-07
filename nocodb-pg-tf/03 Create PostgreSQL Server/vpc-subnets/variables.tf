variable "vpc_name" {
  type = string
  default = "web-service-vpc-tf"
}

variable "web_front_subnets" {
 description = "Public subnets for instances that are directly exposed to web-traffic such as Load balancers, NAT, gateways, bastions etc."
 type =  list(object({zone = string, v4_cidr_blocks = list(string)}))
 default = [{"zone":"ru-central1-b", "v4_cidr_blocks" : ["10.129.0.0/24"]}]
}

variable "nat_ip_address" {
 description = "Static private IP address for the NAT instance"
 type =  string
 default = "10.129.0.100"
}

variable "default_user" {
  type        = string
  default     = "tutorial"
}

variable "private_key_file" {
  type        = string
  default     = "tutorial_id_rsa"
}

variable "webapp_subnets" {
 description = "Isolated subnets for web applications frontend and backend"
 type =  list(object({zone = string, v4_cidr_blocks = list(string)}))
 default = [{"zone":"ru-central1-a", "v4_cidr_blocks" : ["10.130.0.0/24"]},
            {"zone":"ru-central1-b", "v4_cidr_blocks" : ["10.131.0.0/24"]},
            {"zone":"ru-central1-c", "v4_cidr_blocks" : ["10.132.0.0/24"]}]
}