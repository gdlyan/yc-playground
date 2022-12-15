output "network_id" {
  value = module.vpc_subnets.network_id 
}

output "webfront_subnet" {
   value = module.vpc_subnets.webfront_subnet.id
}

output "nat_instance_private_ip" {
   value = module.vpc_subnets.nat_instance_private_ip
}

output "nat_instance_public_ip" {
   value = module.vpc_subnets.nat_instance_public_ip
}

output "pg_data_disk_id" {
   value = module.postgres.pg_data_disk_id
}

output "nocodb_instances" {
   value = module.nocodb.nocodb_instances
}

output "ssh_command" {
   value = "ssh -L 31080:${module.postgres.pg_instance_private_ip}:80 -L 41080:${module.nocodb.nlb_instance_private_ip}:80 -i ~/.ssh/${var.private_key_file}  ${var.default_user}@${module.vpc_subnets.nat_instance_public_ip}"
}