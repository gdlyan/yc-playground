resource "yandex_vpc_network" "web_service_vpc_tf" {
  name = "web-service-vpc-tf"
  description = "Terraform managed VPC for basic web-service"
}


resource "yandex_vpc_subnet" "web_front_subnets" {
  count = length(var.web_front_subnets)
  network_id = yandex_vpc_network.web_service_vpc_tf.id
  name = "${yandex_vpc_network.web_service_vpc_tf.name}-web-front-${var.web_front_subnets[count.index].zone}-${count.index}"
  description = "Public subnet for instances that are directly exposed to web-traffic such as Load balancers, NAT, gateways, bastions"
  zone = var.web_front_subnets[count.index].zone
  v4_cidr_blocks = var.web_front_subnets[count.index].v4_cidr_blocks
}


resource "yandex_vpc_subnet" "webapp_subnets" {
  count = length(var.webapp_subnets)
  network_id = yandex_vpc_network.web_service_vpc_tf.id
  name = "${yandex_vpc_network.web_service_vpc_tf.name}-webapp-${var.webapp_subnets[count.index].zone}-${count.index}"
  description = "Isolated subnet for web applications frontend and backend"
  zone = var.webapp_subnets[count.index].zone
  v4_cidr_blocks = var.webapp_subnets[count.index].v4_cidr_blocks
  route_table_id = yandex_vpc_route_table.nat_route_table_tf.id
}