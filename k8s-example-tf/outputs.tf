output "network_id" {
  value = module.vpc_subnets.network_id 
}

output "subnet" {
   value = module.vpc_subnets.subnets.0.id
}

output "cidr" {
   value = module.vpc_subnets.subnets.0.v4_cidr_blocks[0]
}

output "k8s_cluster_id" {
   value = module.k8s_cluster.k8s_cluster.id
}

output "k8s_cluster_master_ip_address" {
   value = module.k8s_cluster.k8s_cluster.master[0].external_v4_address
}