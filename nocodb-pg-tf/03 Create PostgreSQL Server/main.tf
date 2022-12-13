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