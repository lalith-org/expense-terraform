resource "aws_vpc" "dev" {
  cidr_block = var.dev_vpc_cidr_block

  tags = {
    "Name" = "vpc-${var.env}"
  }
}

resource "aws_vpc_peering_connection" "peering_dev" {
  peer_vpc_id   = var.default_vpc_id
  vpc_id        = aws_vpc.dev.id
  auto_accept   = true

  tags = {
    Name = "VPC Peering ${var.env}"
  }
}

resource "aws_subnet" "frontend_subnet" {
  count             = length(var.frontend_subnet_list)
  vpc_id            = aws_vpc.dev.id
  cidr_block        = var.frontend_subnet_list[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.env}-frontend-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "backend_subnet" {
  count             = length(var.backend_subnet_list)
  vpc_id            = aws_vpc.dev.id
  cidr_block        = var.backend_subnet_list[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.env}-backend-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "mysql_subnet" {
  count             = length(var.mysql_subnet_list)
  vpc_id            = aws_vpc.dev.id
  cidr_block        = var.mysql_subnet_list[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.env}-mysql-subnet-${count.index + 1}"
  }
}

resource "aws_route" "dev_to_default" {
  route_table_id            = aws_vpc.dev.default_route_table_id
  destination_cidr_block    = var.default_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peering_dev.id
}

resource "aws_route" "default_to_dev" {
  route_table_id            = var.default_route_table_id
  destination_cidr_block    = aws_vpc.dev.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peering_dev.id
}