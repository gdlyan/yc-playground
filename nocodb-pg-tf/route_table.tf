resource "yandex_vpc_route_table" "nat_route_table_tf" {
  name = "nat-route-table-tf"
  description = "Terraform managed route table for basic web service"
  network_id = yandex_vpc_network.web_service_vpc_tf.id

  static_route {
     destination_prefix = "0.0.0.0/0"
     next_hop_address = yandex_compute_instance.nat_instance_tf.network_interface.0.ip_address
  }
}