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