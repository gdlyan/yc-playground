variable "vpc_name" {
  type = string
  default = "k8s"
}

variable "subnets" {
 description = "Public subnet for instances that are directly exposed to web-traffic such as Load balancers, NAT, gateways, bastions etc."
 type =  list(object({zone = string, v4_cidr_blocks = list(string)}))
 default = [{"zone":"ru-central1-a", "v4_cidr_blocks" : ["10.129.0.0/24"]},
            {"zone":"ru-central1-b", "v4_cidr_blocks" : ["10.130.0.0/24"]},
            {"zone":"ru-central1-c", "v4_cidr_blocks" : ["10.131.0.0/24"]}]
}

