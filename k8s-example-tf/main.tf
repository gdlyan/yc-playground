provider "yandex" {
  token     = var.token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
}

module "vpc_subnets" {
  source = "./vpc-subnets" 
}

module "k8s_cluster" {
  source    = "./k8s-cluster" 
  folder_id = var.folder_id
  network_id = module.vpc_subnets.network_id
  subnet = module.vpc_subnets.subnets.0
}