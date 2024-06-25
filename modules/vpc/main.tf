resource "aws_vpc" "dev" {
  cidr_block = var.dev_vpc_cidr_block

  tags = {
    "Name" = "vpc-${var.env}"
  }
}

resource "aws_subnet" "subnet_dev" {
  vpc_id     = aws_vpc.dev.id
  cidr_block = var.dev_subnet_cidr_block

  tags = {
    Name = "subnet-${var.env}"
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