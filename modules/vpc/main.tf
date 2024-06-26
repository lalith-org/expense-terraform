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

# creating 2 public subnets
resource "aws_subnet" "public_subnet" {
  count             = length(var.public_subnet_list)
  vpc_id            = aws_vpc.dev.id
  cidr_block        = var.public_subnet_list[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

# for providing internet to subnets
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.dev.id

  tags = {
    Name = "igw-${var.env}"
  }
}

# creating 2 route tables for 2 VPCs
resource "aws_route_table" "frontend_rt" {
  count   = length(var.frontend_subnet_list)
  vpc_id  = aws_vpc.dev.id

  route {
    cidr_block                = var.default_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.peering_dev.id
  }

  tags = {
    Name = "frontend-rt-${count.index + 1}"
  }
}

resource "aws_route_table" "backend_rt" {
  count   = length(var.backend_subnet_list)
  vpc_id  = aws_vpc.dev.id

  route {
    cidr_block                = var.default_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.peering_dev.id
  }

  tags = {
    Name = "backend-rt-${count.index + 1}"
  }
}

resource "aws_route_table" "mysql_rt" {
  count   = length(var.mysql_subnet_list)
  vpc_id  = aws_vpc.dev.id

  route {
    cidr_block                = var.default_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.peering_dev.id
  }

  tags = {
    Name = "mysql-rt-${count.index + 1}"
  }
}

# associate route tables created with subnets

resource "aws_route_table_association" "fe-subnet-rt-assn" {
  count          = length(var.frontend_subnet_list)
  subnet_id      = aws_subnet.frontend_subnet[count.index].id
  route_table_id = aws_route_table.frontend_rt[count.index].id
}

resource "aws_route_table_association" "be-subnet-rt-assn" {
  count          = length(var.backend_subnet_list)
  subnet_id      = aws_subnet.backend_subnet[count.index].id
  route_table_id = aws_route_table.backend_rt[count.index].id
}

resource "aws_route_table_association" "mysql-subnet-rt-assn" {
  count          = length(var.mysql_subnet_list)
  subnet_id      = aws_subnet.mysql_subnet[count.index].id
  route_table_id = aws_route_table.mysql_rt[count.index].id
}

# create route tables for public subnets

resource "aws_route_table" "public_rt" {
  count   = length(var.public_subnet_list)
  vpc_id  = aws_vpc.dev.id

  route {
    cidr_block                = var.default_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.peering_dev.id
  }

  tags = {
    Name = "public-rt-${count.index + 1}"
  }
}