output "network_id" {
  value = yandex_vpc_network.vpc.id  
}

output "subnets" {
  value = [for s in yandex_vpc_subnet.subnets: {"id":s.id,
                                                "zone":s.zone, 
                                                "v4_cidr_blocks":s.v4_cidr_blocks}]
}