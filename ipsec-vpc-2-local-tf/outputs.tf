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

output "local_public_ip" {
   value = var.local_public_ip
}

output "local_subnet" {
   value = var.local_subnet
}

output "psk" {
   value = random_string.psk.result
   sensitive = true
}

output "managed_db_conn_string" {
   value = module.managed_db.conn_string
   sensitive = true
}

output "reverse_proxy_public_ip" {
   value = module.proxy.reverse_proxy_public_ip
}