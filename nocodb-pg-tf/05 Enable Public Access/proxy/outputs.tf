output "reverse_proxy_public_ip" {
   description = "Public IP of Nginx reverse proxy"
   value       = yandex_compute_instance.proxy_docker_instance.network_interface.0.nat_ip_address
}