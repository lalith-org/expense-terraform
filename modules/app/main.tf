resource "aws_security_group" "main" {
  name        = "${var.component}-${var.env}-sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.component}-${var.env}-sg"
  }
}

resource "aws_instance" "vm" {
  ami                     = data.aws_ami.example.id
  instance_type           = var.instance_type
  vpc_security_group_ids  = [aws_security_group.main.id]
  subnet_id                = var.subnets[0]

  tags = {
  Name = var.component
  Monitor = "true"
  env = var.env
  }
}

resource "aws_route53_record" "domain" {
  zone_id = var.zone_id
  name    = "${var.component}-${var.env}"
  type    = "A"
  ttl     = 30
  records = [aws_instance.vm.private_ip]
}

resource "null_resource" "null1" {
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = jsondecode(data.vault_generic_secret.ssh_creds.data_json).ansible_user
      password = jsondecode(data.vault_generic_secret.ssh_creds.data_json).ansible_password
      host     = aws_instance.vm.private_ip
    }

    inline = [
      "sudo pip3.11 install ansible hvac",
      "sudo pip3.11 install ansible-core",
      "ansible-pull -i localhost, -U https://github.com/lalith2211/expense-ansible.git get-secrets.yml -e env=${var.env} -e role=${var.component}  -e vault_token=${var.vault_token}",
      "ansible-pull -i localhost, -U https://github.com/lalith2211/expense-ansible.git ansible.yml -e env=${var.env} -e role=${var.component} -e @secrets.json -e @app.json",
      "sudo rm -rf *"
      #"ansible-pull -U https://github.com/lalith2211/expense-ansible.git ansible.yml -i localhost, -e env=${var.env} -e role=${var.component}",
    ]
  }
}

# creating a load balancer
resource "aws_lb" "test" {
  count    = var.lb_needed ? 1 : 0
  name               = "${var.component}-${var.env}-alb"
  internal           = var.lb_type == "public" ? false : true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.main.id]
  subnets            = var.lb_subnets

  enable_deletion_protection = true

  tags = {
    Name = "${var.component}-${var.env}-sg"
  }
}


