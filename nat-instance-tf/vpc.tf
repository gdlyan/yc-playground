terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    } 
    local = {
      source = "hashicorp/local"
      version = "2.2.3"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token     = var.token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
}

resource "yandex_vpc_network" "nat_instance_vpc_tf" {
  name = var.nat_instance_vpc_name
  description = "Terraform managed VPC for Routing through a NAT instance tutorial"
}

resource "yandex_vpc_subnet" "nat_instance_public_subnet" {
  network_id = yandex_vpc_network.nat_instance_vpc_tf.id
  name = "public-subnet-tf"
  description = "Public Terraform managed subnet for Routing through a NAT instance tutorial"
  zone = "ru-central1-a" 
  v4_cidr_blocks = ["10.128.0.0/24"]
}

resource "yandex_vpc_route_table" "route_table_tf" {
  name = "route-table-tf"
  description = "Terraform managed route table for Routing through a NAT instance tutorial"
  network_id = yandex_vpc_network.nat_instance_vpc_tf.id

  static_route {
     destination_prefix = "0.0.0.0/0"
     next_hop_address = yandex_compute_instance.nat_instance_tf.network_interface.0.ip_address
  }
}


resource "yandex_vpc_subnet" "nat_instance_private_subnet" {
  network_id = yandex_vpc_network.nat_instance_vpc_tf.id
  name = "private-subnet-tf"
  description = "Private Terraform managed subnet for Routing through a NAT instance tutorial"
  zone = "ru-central1-b"
  v4_cidr_blocks = ["10.129.0.0/24"]
  route_table_id = yandex_vpc_route_table.route_table_tf.id
}






