output "network_id" {
  value = yandex_vpc_network.vpc.id  
}

output "webfront_subnet" {
   value = {"id":yandex_vpc_subnet.web_front_subnets.0.id,
            "zone":yandex_vpc_subnet.web_front_subnets.0.zone,
            "v4_cidr_blocks":yandex_vpc_subnet.web_front_subnets.0.v4_cidr_blocks} 
}

output "webapp_subnets" {
  value = [for s in yandex_vpc_subnet.webapp_subnets: {"id":s.id,
                                                       "zone":s.zone, 
                                                       "v4_cidr_blocks":s.v4_cidr_blocks}]
}

output "ipsec_instance_private_ip" {
   description = "Private IP of IPSec instance and ssh bastion"
   value       = yandex_compute_instance.ipsec_instance_tf.network_interface.0.ip_address
}

output "ipsec_instance_public_ip" {
   description = "Public IP of IPSec instance and ssh bastion"
   value       = yandex_compute_instance.ipsec_instance_tf.network_interface.0.nat_ip_address
}