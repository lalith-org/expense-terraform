#module "frontend" {
#  depends_on       = [module.backend]
#  source           = "./modules/app"
#  instance_type    = var.instance_type
#  component        = "frontend"
#  env              = var.env
#  zone_id          = var.zone_id
#  vault_token      = var.vault_token
#  subnets          = module.vpc.frontend_subnet_list
#  vpc_id           = module.vpc.vpc_id
#  lb_needed        = "true"
#  lb_type          = "public"
#  lb_subnets       = module.vpc.lb_subnets_list
#  app_port         = 80
#  bastion_nodes    = var.bastion_nodes
#  prometheus_nodes = var.prometheus_nodes
#  server_app_port_sg_cidr = var.public_subnet_list
#  lb_app_port_sg_cidr     = ["0.0.0.0/0"]
#  lb_ports = {"https":443, "http":80}
#  kms_key_id  = var.kms_key_id
#}
#
#module "backend" {
#  depends_on       = [module.rds]
#  source           = "./modules/app"
#  instance_type    = var.instance_type
#  component        = "backend"
#  env              = var.env
#  zone_id          = var.zone_id
#  vault_token      = var.vault_token
#  subnets          = module.vpc.backend_subnet_list
#  vpc_id           = module.vpc.vpc_id
#  lb_needed        = "true"
#  lb_type          = "private"
#  lb_subnets       = module.vpc.backend_subnet_list
#  app_port         = 8080
#  bastion_nodes    = var.bastion_nodes
#  prometheus_nodes = var.prometheus_nodes
#  server_app_port_sg_cidr = concat(var.frontend_subnet_list, var.backend_subnet_list)
#  lb_app_port_sg_cidr     = var.frontend_subnet_list
#  lb_ports = {"http":8080}
#  kms_key_id  = var.kms_key_id
#}

module "rds" {
  source            = "./modules/rds"
  rds_engine        = "mysql"
  engine_version    = "8.0.36"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  component         = "mysql"
  family            = "mysql8.0"
  env               = var.env
  subnet_ids        = module.vpc.mysql_subnet_list
  vpc_id        = module.vpc.vpc_id
  server_app_port_sg_cidr = var.backend_subnet_list
  kms_key_id  = var.kms_key_id
  storage_type            = "gp3"
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
  public_subnet_list      = var.public_subnet_list
}