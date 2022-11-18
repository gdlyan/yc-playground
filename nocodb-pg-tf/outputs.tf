output "webapp_instance_private_ip" {
   description = "Private IP of webapp instance"
   value       = yandex_compute_instance.webapp_instances[*].network_interface.0.ip_address
}

output "webapp_instance_public_ip" {
   description = "Public IP of webapp instance"
   value       = yandex_compute_instance.webapp_instances[*].network_interface.0.nat_ip_address
}

output "pg_docker_instance_private_ip" {
   description = "Private IP of Postgres and pgadmin"
   value       = yandex_compute_instance.pg_docker_instances.0.network_interface.0.ip_address
}

output "pg_docker_instance_public_ip" {
   description = "Public IP of Postgres and pgadmin"
   value       = yandex_compute_instance.pg_docker_instances.0.network_interface.0.nat_ip_address
}

output "nat_instance_private_ip" {
   description = "Private IP of NAT instance and ssh bastion"
   value       = yandex_compute_instance.nat_instance_tf.network_interface.0.ip_address
}

output "nat_instance_public_ip" {
   description = "Public IP of NAT instance and ssh bastion"
   value       = yandex_compute_instance.nat_instance_tf.network_interface.0.nat_ip_address
}



output "nlb_listener_address" {
   description = "Public IP of network load balancer"
   value       = [for s in yandex_lb_network_load_balancer.nlb.listener: s.external_address_spec.*.address].0[0]
}