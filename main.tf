resource "aws_instance" "frontend" {
  for_each = var.components
  ami           = var.ami_id
  instance_type = each.value["ins_type"]
  vpc_security_group_ids = var.security_groups

  tags = {
    Name = each.key
  }
}

variable "components" {
  default = {
    frontend = {
      ins_type = "t3.micro"
    }

    backend = {
      ins_type = "t3.micro"
    }

    mysql = {
      ins_type = "t3.small"
    }
  }
}