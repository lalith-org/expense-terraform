instance_type = "t3.small"
zone_id = "Z08164623BYHI8XGQC72A"
env = "dev"
dev_vpc_cidr_block = "10.10.0.0/24"
default_cidr_block = "10.10.0.0/24"
default_vpc_cidr = "172.31.0.0/16"
default_vpc_id = "vpc-0ac03e097c085256c"
default_route_table_id = "rtb-0c937dd01d450a295"
frontend_subnet_list = ["10.10.0.0/27","10.10.0.32/27"]
backend_subnet_list = ["10.10.0.64/27","10.10.0.96/27"]
mysql_subnet_list = ["10.10.0.128/27","10.10.0.160/27"]
availability_zones = ["us-east-1a", "us-east-1b"]

# subnets for NAT gateway
public_subnet_list = ["10.10.0.192/27","10.10.0.224/27"]
bastion_nodes = ["172.31.82.22/32"]
prometheus_nodes = ["172.31.43.186/32"]