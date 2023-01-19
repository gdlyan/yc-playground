# Create VPC
resource "yandex_vpc_network" "vpc" {
  name = "${var.vpc_name}-vpc-tf"
  description = "Terraform managed VPC for ${var.vpc_name} example"
}


# Create gateway
resource "yandex_vpc_gateway" "k8s_vpc_gateway" {
  name = "${var.vpc_name}-vpc-gateway"
  shared_egress_gateway {}
} 

# Create route table
resource "yandex_vpc_route_table" "nat_route_table_tf" {
  name = "${var.vpc_name}-route-table-tf"
  description = "Terraform managed route table for basic web service"
  network_id = yandex_vpc_network.vpc.id

  static_route {
     destination_prefix = "0.0.0.0/0"
     gateway_id = yandex_vpc_gateway.k8s_vpc_gateway.id
  }
}

# Create subnets
resource "yandex_vpc_subnet" "subnets" {
  count = length(var.subnets)
  network_id = yandex_vpc_network.vpc.id
  name = "${var.vpc_name}-${var.subnets[count.index].zone}-${count.index}"
  description = "Subnets attached to shared egress gateway"
  zone = var.subnets[count.index].zone
  v4_cidr_blocks = var.subnets[count.index].v4_cidr_blocks
  route_table_id = yandex_vpc_route_table.nat_route_table_tf.id
}

