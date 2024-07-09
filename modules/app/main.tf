resource "aws_security_group" "main" {
  name        = "${var.component}-${var.env}-sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = var.vpc_id

  # app port
  ingress {
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "TCP"
    cidr_blocks     = var.server_app_port_sg_cidr
  }

  # SSH
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "TCP"
    cidr_blocks     = var.bastion_nodes
  }

  # Prometheus
  ingress {
    from_port       = 9100
    to_port         = 9100
    protocol        = "TCP"
    cidr_blocks     = var.prometheus_nodes
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


resource "aws_security_group" "load-balancer" {
  count       = var.lb_needed ? 1 : 0
  name        = "${var.component}-${var.env}-lb"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = var.vpc_id

  # app port

  dynamic "ingress" {
    for_each = var.lb_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol       = "TCP"
      cidr_blocks = var.lb_app_port_sg_cidr
    }
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

  root_block_device = {
    encrypted = true
    kms_key_id = var.kms_key_id
  }

  tags = {
  Name = var.component
  Monitor = "true"
  env = var.env
  }
}

resource "aws_route53_record" "server" {
  count   = var.lb_needed ? 0 : 1
  zone_id = var.zone_id
  name    = "${var.component}-${var.env}"
  type    = "A"
  ttl     = 30
  records = [aws_instance.vm.private_ip]
}


resource "aws_route53_record" "load_balancer" {
  count   = var.lb_needed ? 1 : 0
  zone_id = var.zone_id
  name    = "${var.component}-${var.env}"
  type    = "CNAME"
  ttl     = 30
  records = [aws_lb.test[0].dns_name]
}

resource "null_resource" "null1" {

  triggers = {
    instance = aws_instance.vm.id
  }

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
      "ansible-pull -i localhost, -U https://github.com/lalith2211/expense-ansible.git ansible.yml -e env=${var.env} -e role=${var.component} -e @secrets.json",
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
  security_groups    = [aws_security_group.load-balancer[0].id]
  subnets            = var.lb_subnets

  enable_deletion_protection = false

  tags = {
    Name = "${var.component}-${var.env}-sg"
  }
}


# target groups for load balancers
resource "aws_lb_target_group" "tg" {
  count                 = var.lb_needed ? 1 : 0
  name                  = "${var.component}-${var.env}-tg"
  port                  = var.app_port
  protocol              = "HTTP"
  vpc_id                = var.vpc_id
  deregistration_delay  = 15

  health_check {
    healthy_threshold   = 2
    interval            = 5
    path                = "/health"
    port                = var.app_port
    timeout             = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "tg-ga" {
  count    = var.lb_needed ? 1 : 0
  target_group_arn = aws_lb_target_group.tg[0].arn
  target_id        = aws_instance.vm.id
  port             = var.app_port
}

# redirect the HTTP request to HTTPS port
resource "aws_lb_listener" "frontend_http" {
  count             = var.lb_needed && var.lb_type == "public" ? 1 : 0
  load_balancer_arn = aws_lb.test[0].arn
  port              = var.app_port
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# accepting the HTTPS requests
resource "aws_lb_listener" "frontend_https" {
  count             = var.lb_needed && var.lb_type == "public" ? 1 : 0
  load_balancer_arn = aws_lb.test[0].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = "arn:aws:acm:us-east-1:730335477956:certificate/52a63498-506f-458d-a938-3084db5812db"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg[0].arn
  }
}

resource "aws_lb_listener" "backend" {
  count             = var.lb_needed && var.lb_type != "public" ? 1 : 0
  load_balancer_arn = aws_lb.test[0].arn
  port              = var.app_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg[0].arn
  }
}