resource "aws_db_instance" "default" {
  identifier           = "${var.component}-${var.env}"
  allocated_storage    = var.allocated_storage
  db_name              = "mydb"
  engine               = var.rds_engine #done
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  username             = jsondecode(data.vault_generic_secret.ssh_creds.data_json).rds_username
  password             = jsondecode(data.vault_generic_secret.ssh_creds.data_json).rds_password
  parameter_group_name = aws_db_parameter_group.default.name
  skip_final_snapshot  = true
  multi_az             = false
  publicly_accessible  = false
  db_subnet_group_name = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.main.id]
  kms_key_id              = var.kms_key_id
  storage_encrypted       = true
  storage_type            = var.storage_type
}

resource "aws_db_parameter_group" "default" {
  name   = "${var.component}-${var.env}-pg"
  family = var.family
}

resource "aws_db_subnet_group" "default" {
  name       = "${var.component}-${var.env}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.component}-${var.env}-subnet-group"
  }
}

resource "aws_security_group" "main" {
  name        = "${var.component}-${var.env}-sg"
  description = "${var.component}-${var.env}-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "TCP"
    cidr_blocks = var.server_app_port_sg_cidr
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.component}-${var.env}-sg"
  }
}