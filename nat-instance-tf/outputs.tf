output "vpc_name" {
  description = "Name of the VPC"
  value       = yandex_vpc_network.nat_instance_vpc_tf.name
}
 
output "nat_instance_public_ip" {
  description = "Public IP of NAT instance"
  value       = yandex_compute_instance.nat_instance_tf.network_interface.0.nat_ip_address
}
 
output "test_instance_private_ip" {
   description = "Private IP of test instance"
   value       = yandex_compute_instance.test_vm_tf.network_interface.0.ip_address
}
