variable "env" {}
variable "service_name" {}
variable "vpc_id" {}
variable "pub_ids" {}
variable "acm_arn" {}
variable "route53_id" {}
variable "route53_name" {}
locals {
  name     = "${var.env}-${var.service_name}"
  targets  = ["${var.env}-${var.service_name}-web-ecs-blue", "${var.env}-${var.service_name}-web-ecs-green"]
  des_cidr = "0.0.0.0/0"
}

# SecurityGroup
resource "aws_security_group" "alb" {
  name        = "${local.name}-alb"
  description = "${var.env}:${var.service_name} LoadBalancer"
  vpc_id      = var.vpc_id

  # allow from internet
  egress {
    from_port = 0
    to_port   = 0
    # allow all protocols
    protocol    = "-1"
    cidr_blocks = [local.des_cidr]
  }

  tags = {
    Name = "${local.name}-alb"
  }
}
# SecurityGroup Rule (HTTPS)
resource "aws_security_group_rule" "https" {
  security_group_id = aws_security_group.alb.id

  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = [local.des_cidr]
}
# SecurityGroup Rule (HTTP)
resource "aws_security_group_rule" "http" {
  security_group_id = aws_security_group.alb.id

  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = [local.des_cidr]
}

# LoadBalancer
resource "aws_lb" "web" {
  name               = "${local.name}-web"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = flatten(var.pub_ids)

  # allow to delete alb from terraform
  enable_deletion_protection = false

  tags = {
    Name    = "${local.name}-web"
    service = var.service_name
    env     = var.env
  }
}
# LB_TargetGroup(Blue/Green)
resource "aws_lb_target_group" "ecs-web" {
  count  = length(local.targets)
  name   = local.targets[count.index]
  vpc_id = var.vpc_id

  # traffic distribution
  port                 = 80
  protocol             = "HTTP"
  target_type          = "ip"
  deregistration_delay = 30

  # healthcheck container(ECS)
  health_check {
    protocol = "HTTP"
    path     = "/"
    port     = 80
    interval = 10
    timeout  = 3
    # number of consective healthcheck faiures
    healthy_threshold   = 2
    unhealthy_threshold = 2
    # 401 (Basic Authentication)
    matcher = "200,401"
  }
}
# LB_Listener
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_arn

  default_action {
    # choose blue target
    target_group_arn = aws_lb_target_group.ecs-web[0].arn
    type             = "forward"
  }

  # Dynamic (Blue/Green Deployment)
  lifecycle {
    ignore_changes = [default_action]
  }
}
# LB_Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  # 301 HTTP->HTTPS
  default_action {
    type = "redirect"

    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Add loadbalancer's record to Route53
resource "aws_route53_record" "lb-web" {
  zone_id = var.route53_id
  name    = "${var.env}.${var.route53_name}"
  type    = "CNAME"
  ttl     = 60
  records = [aws_lb.web.dns_name]
}