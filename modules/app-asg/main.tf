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

  ingress {
    from_port   = 2019
    to_port     = 2019
    protocol    = "TCP"
    cidr_blocks = var.prometheus_nodes
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

resource "aws_launch_template" "main" {
  name                    = "${var.component}-${var.env}"
  image_id                = data.aws_ami.example.id
  instance_type           = var.instance_type
  vpc_security_group_ids  = [aws_security_group.main.id]

  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    component   = var.component
    env         = var.env
    vault_token = var.vault_token
  }))

}

resource "aws_autoscaling_group" "bar" {
  desired_capacity   = var.min_capacity
  max_size           = var.max_capacity
  min_size           = var.min_capacity
  vpc_zone_identifier = var.subnets
  target_group_arns = [aws_lb_target_group.tg.arn]

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.component}-${var.env}"
    propagate_at_launch = true
  }

  tag {
    key                 = "monitor"
    value               = "yes"
    propagate_at_launch = true
  }

  tag {
    key                 = "env"
    value               = var.env
    propagate_at_launch = true
  }

}


resource "aws_autoscaling_policy" "main" {
  name                   = "target-cpu"
  autoscaling_group_name = aws_autoscaling_group.bar.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}

resource "aws_lb_target_group" "tg" {
  name                 = "${var.env}-${var.component}-tg"
  port                 = var.app_port
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  deregistration_delay = 15

  health_check {
    healthy_threshold   = 2
    interval            = 5
    path                = "/health"
    port                = var.app_port
    timeout             = 2
    unhealthy_threshold = 2
  }
}

resource "aws_security_group" "load-balancer" {
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

resource "aws_lb" "test" {
  name               = "${var.component}-${var.env}-alb"
  internal           = var.lb_type == "public" ? false : true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load-balancer.id]
  subnets            = var.lb_subnets

  enable_deletion_protection = false

  tags = {
    Name = "${var.component}-${var.env}-sg"
  }
}

#resource "aws_lb_target_group_attachment" "tg-ga" {
#  target_group_arn = aws_lb_target_group.tg.arn
#  target_id        = aws_autoscaling_group.bar.id
#  port             = var.app_port
#}

# redirect the HTTP request to HTTPS port
resource "aws_lb_listener" "frontend_http" {
  count             = var.lb_type == "public" ? 1 : 0
  load_balancer_arn = aws_lb.test.arn
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
  count             = var.lb_type == "public" ? 1 : 0
  load_balancer_arn = aws_lb.test.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = "arn:aws:acm:us-east-1:730335477956:certificate/52a63498-506f-458d-a938-3084db5812db"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_listener" "backend" {
  count             = var.lb_type != "public" ? 1 : 0
  load_balancer_arn = aws_lb.test.arn
  port              = var.app_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_route53_record" "load_balancer" {
  zone_id = var.zone_id
  name    = "${var.component}-${var.env}"
  type    = "CNAME"
  ttl     = 30
  records = [aws_lb.test.dns_name]
}
