variable "instance_type" {}
#variable "component" {}
variable "env" {}
variable "zone_id" {}
variable "vault_token" {} # the value for this variable will be provided in env vars by pipeline
variable "dev_vpc_cidr_block" {}
#variable "dev_subnet_cidr_block" {}
variable "default_vpc_id" {}
variable "default_vpc_cidr" {}
variable "default_route_table_id" {}