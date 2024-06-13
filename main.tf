module "frontend" {
  source = "./modules/app"
  instance_type = var.instance_type
  component = var.component
  os_pass = var.os_pass
  os_user = var.os_user
  env = var.env
  zone_id = var.zone_id
}

#module "backend" {
#  source = "./modules/app"
#  instance_type = var.instance_type
#  component = var.component
#  os_pass = var.os_pass
#  os_user = var.os_user
#  env = var.env
#  zone_id = var.zone_id
#}
#
#module "mysql" {
#  source = "./modules/app"
#  instance_type = var.instance_type
#  component = var.component
#  os_pass = var.os_pass
#  os_user = var.os_user
#  env = var.env
#  zone_id = var.zone_id
#}