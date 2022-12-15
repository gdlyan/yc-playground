provider "yandex" {
  token     = var.token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
}

module "vpc_subnets" {
  source = "./vpc-subnets" 
}

module "postgres" {
  source = "./postgres" 
  subnet = module.vpc_subnets.webapp_subnets[0]
  recreate_data_disk = var.recreate_data_disk
  postgres_password = var.postgres_password
  pgadmin_credentials = var.pgadmin_credentials
}

module "nocodb" {
  source                 = "./nocodb"
  folder_id              = var.folder_id
  pg_instance_private_ip = module.postgres.pg_instance_private_ip
  postgres_password      = var.postgres_password
  subnet_ids             = [for s in module.vpc_subnets.webapp_subnets: s.id]
  zones                  = [for s in module.vpc_subnets.webapp_subnets: s.zone]
  nlb_subnet             = module.vpc_subnets.webfront_subnet
}