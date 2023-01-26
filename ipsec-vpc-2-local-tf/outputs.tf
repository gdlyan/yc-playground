output "network_id" {
  value = module.vpc_subnets.network_id 
}

output "webfront_subnet" {
   value = module.vpc_subnets.webfront_subnet.id
}

output "ipsec_instance_private_ip" {
   value = module.vpc_subnets.ipsec_instance_private_ip
}

output "ipsec_instance_public_ip" {
   value = module.vpc_subnets.ipsec_instance_public_ip
}