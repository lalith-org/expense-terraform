module "frontend" {
  depends_on    = [module.backend]
  source        = "./modules/app"
  instance_type = var.instance_type
  component     = "frontend"
  env           = var.env
  zone_id       = var.zone_id
  vault_token   = var.vault_token
  subnets       = module.vpc.frontend_subnet_list
  vpc_id        = module.vpc.vpc_id
}

module "backend" {
  depends_on    = [module.mysql]
  source        = "./modules/app"
  instance_type = var.instance_type
  component     = "backend"
  env           = var.env
  zone_id       =  var.zone_id
  vault_token   = var.vault_token
  subnets       = module.vpc.backend_subnet_list
  vpc_id        = module.vpc.vpc_id
}

module "mysql" {
  source        = "./modules/app"
  instance_type = var.instance_type
  component     = "mysql"
  env           = var.env
  zone_id       = var.zone_id
  vault_token   = var.vault_token
  subnets       = module.vpc.mysql_subnet_list
  vpc_id        = module.vpc.vpc_id

}

module "vpc" {
  source                  = "./modules/vpc"
  dev_vpc_cidr_block      = var.dev_vpc_cidr_block
#  dev_subnet_cidr_block = var.dev_subnet_cidr_block
  default_vpc_id          = var.default_vpc_id
  default_vpc_cidr        = var.default_vpc_cidr
  default_route_table_id  = var.default_route_table_id
  frontend_subnet_list    = var.frontend_subnet_list
  backend_subnet_list     = var.backend_subnet_list
  mysql_subnet_list       = var.mysql_subnet_list
  availability_zones      = var.availability_zones
  env                     = var.env
}