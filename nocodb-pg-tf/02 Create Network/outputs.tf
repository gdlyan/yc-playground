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