provider "yandex" {
  token     = var.token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
}

module "vpc_subnets" {
  source = "./vpc-subnets" 
}

module "ipsec_config" {
  source = "./ipsec-config" 
  ipsec_instance_public_ip = module.vpc_subnets.ipsec_instance_public_ip
  cloud_subnet = module.vpc_subnets.webfront_subnet.v4_cidr_blocks.0
  local_public_ip = var.local_public_ip
  local_subnet    = var.local_subnet
  ipsec_conf_local_dir = local.ipsec_conf_local_dir 
  psk = random_string.psk.result    
}