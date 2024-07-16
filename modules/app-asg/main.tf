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

resource "aws_launch_template" "asg-launch-template" {
  name_prefix   = "${var.env}-${var.component}"
  image_id      = data.aws_ami.example.id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.main.id]

  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    component   = var.component
    env         = var.env
    vault_token = var.vault_token
  }))
}

resource "aws_autoscaling_group" "bar" {
  availability_zones = ["us-east-1a"]
  desired_capacity   = var.min_capacity
  max_size           = var.max_capacity
  min_size           = var.min_capacity

  launch_template {
    id      = aws_launch_template.asg-launch-template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.component}-${var.env}"
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

resource "aws_lb_target_group" "main" {
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