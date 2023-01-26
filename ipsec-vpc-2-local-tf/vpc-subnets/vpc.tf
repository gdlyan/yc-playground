# Create VPC
resource "yandex_vpc_network" "vpc" {
  name = var.vpc_name
  description = "Terraform managed VPC for basic web-service"
}

# Create web-front subnet
resource "yandex_vpc_subnet" "web_front_subnets" {
  count = length(var.web_front_subnets)
  network_id = yandex_vpc_network.vpc.id
  name = "${var.vpc_name}-front-${var.web_front_subnets[count.index].zone}-${count.index}"
  description = "Public subnet for instances that are directly exposed to web-traffic such as Load balancers, NAT, gateways, bastions"
  zone = var.web_front_subnets[count.index].zone
  v4_cidr_blocks = var.web_front_subnets[count.index].v4_cidr_blocks
}

# Create route table
resource "yandex_vpc_route_table" "ipsec_rt_tf" {
  name = "ipsec-rt-tf"
  description = "Terraform managed route table for basic web service"
  network_id = yandex_vpc_network.vpc.id

  static_route {
     destination_prefix = var.local_subnet
     next_hop_address = var.ipsec_ip_address
  }
}

#Create private subnets
resource "yandex_vpc_subnet" "webapp_subnets" {
  count = length(var.webapp_subnets)
  network_id = yandex_vpc_network.vpc.id
  name = "${var.vpc_name}-back-${var.webapp_subnets[count.index].zone}-${count.index}"
  description = "Isolated subnet for web applications frontend and backend"
  zone = var.webapp_subnets[count.index].zone
  v4_cidr_blocks = var.webapp_subnets[count.index].v4_cidr_blocks
  route_table_id = yandex_vpc_route_table.ipsec_rt_tf.id
}