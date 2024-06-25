resource "aws_vpc" "dev" {
  cidr_block = var.dev_vpc_cidr_block

  tags = {
    "Name" = "vpc-${var.env}"
  }
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.dev.id
  cidr_block = var.dev_subnet_cidr_block

  tags = {
    Name = "subnet-${var.env}"
  }
}