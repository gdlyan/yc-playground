provider "yandex" {
  token     = var.token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
}

module "vpc_subnets" {
  source = "./vpc-subnets" 
  local_subnet    = var.local_subnet
  local_public_ip = var.local_public_ip
}

module "ipsec_config" {
  source = "./ipsec-config" 
  ipsec_instance_public_ip = module.vpc_subnets.ipsec_instance_public_ip
  # cloud_subnet = module.vpc_subnets.webfront_subnet.v4_cidr_blocks.0
  local_public_ip = var.local_public_ip
  local_subnet    = var.local_subnet
  ipsec_conf_local_dir = local.ipsec_conf_local_dir 
  psk = random_string.psk.result    
}

module "managed_db" {
  network_id = module.vpc_subnets.network_id
  subnets = module.vpc_subnets.webapp_subnets
  source = "./managed-db"
  dbname = "nocodb"
  dbuser = "dbuser"
  sg_mdb_id = module.vpc_subnets.sg_mdb_id
}

module "app_cluster" {
  source                 = "./app-cluster"
  folder_id              = var.folder_id
  conn_string            = module.managed_db.conn_string
  subnet_ids             = [for s in module.vpc_subnets.webapp_subnets: s.id]
  zones                  = [for s in module.vpc_subnets.webapp_subnets: s.zone]
  nlb_subnet             = module.vpc_subnets.webfront_subnet
  sg_app_id              = module.vpc_subnets.sg_app_id
}

module "proxy" {
  source                  = "./proxy"
  nlb_instance_private_ip = module.app_cluster.nlb_instance_private_ip
  proxy_subnet            = module.vpc_subnets.webfront_subnet
  domain                  = var.domain 
  sg_proxy_id             = module.vpc_subnets.sg_proxy_id
}