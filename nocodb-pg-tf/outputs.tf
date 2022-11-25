output "webapp_instance_private_ip" {
   description = "Private IP of webapp instance"
   value       = yandex_compute_instance.webapp_instances[*].network_interface.0.ip_address
}

output "pg_docker_instance_private_ip" {
   description = "Private IP of Postgres and pgadmin"
   value       = yandex_compute_instance.pg_docker_instances.0.network_interface.0.ip_address
}


output "nat_instance_private_ip" {
   description = "Private IP of NAT instance and ssh bastion"
   value       = yandex_compute_instance.nat_instance_tf.network_interface.0.ip_address
}

output "nat_instance_public_ip" {
   description = "Public IP of NAT instance and ssh bastion"
   value       = yandex_compute_instance.nat_instance_tf.network_interface.0.nat_ip_address
}

output "nginx_instance_private_ip" {
   description = "Private IP of nginx web proxy"
   value       = yandex_compute_instance.proxy_docker_instance.network_interface.0.ip_address
}

output "nginx_instance_public_ip" {
   description = "Public IP of nginx web proxy"
   value       = yandex_compute_instance.proxy_docker_instance.network_interface.0.nat_ip_address
}

output "nlb_listener_address" {
   description = "Private IP of network load balancer"
   value       = [for s in yandex_lb_network_load_balancer.nlb.listener: s.internal_address_spec.*.address].0[0]
}

## So far the network load balancer is behind proxy, hence no public IP. If otherwise required do uncomment below and comment the above output blocks 
/*
output "nlb_listener_address" {
   description = "Public IP of network load balancer"
   value       = [for s in yandex_lb_network_load_balancer.nlb.listener: s.external_address_spec.*.address].0[0]
}
*/

