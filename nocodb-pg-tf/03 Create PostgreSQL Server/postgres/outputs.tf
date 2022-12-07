output "pg_instance_private_ip" {
   description = "Private IP of virtual machine with postgres and pgadmin"
   value       = yandex_compute_instance.pg_docker_instance.network_interface.0.ip_address
}

output "pg_data_disk_id" {
   description = "Persistent data volume for postgres"
   value       = yandex_compute_instance.pg_docker_instance.secondary_disk[0].disk_id
}
