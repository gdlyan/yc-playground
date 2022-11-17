resource "yandex_vpc_route_table" "vpn_route_table_tf" {
  name = "vpn-route-table-tf"
  description = "Terraform managed route table for basic web service"
  network_id = yandex_vpc_network.web_service_vpc_tf.id

  static_route {
     destination_prefix = "192.168.100.0/24"
     next_hop_address = yandex_compute_instance.ipsec_instances.0.network_interface.0.ip_address
  }
}