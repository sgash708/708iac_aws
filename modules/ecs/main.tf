variable "env" {}
variable "service_name" {}
variable "region" {}
variable "id" {}
variable "image" {}
variable "vpc_id" {}
variable "cidr" {}
variable "pri_ids" {}
variable "lb_blue_id" {}
variable "lb_listener" {}
variable "command" {}
locals {
  name = format("%s-%s-%s", var.env, var.service_name, "web")
}

# CloudWatch
resource "aws_cloudwatch_log_group" "ecs_task_web" {
  name              = "${var.env}_ecs_task_web"
  retention_in_days = 7
}
# Role
data "aws_iam_role" "ecs-task" {
  name = "ecsTaskExecutionRole"
}
resource "aws_iam_role_policy_attachment" "ecs-task" {
  role       = data.aws_iam_role.ecs-task.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_iam_role_policy_attachment" "ecr-read-policy" {
  role       = data.aws_iam_role.ecs-task.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSNReadOnlyAccess"
}
resource "aws_iam_role_policy" "ecs-task" {
  name = "ecsTaskExecutionRolePolicy"
  role = data.aws_iam_role.ecs-task.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameters",
        "ssm:DescribeParameters",
        "ssm:GetParameter",
        "ssm:GetParameterHistory",
        "secretsmanager:GetSecretValue",
        "kms:Decrypt"
      ],
      "Resource": [
        "arn:aws:ssm:${var.region}:${var.id}:parameter/*",
        "arn:aws:kms:${var.region}:${var.id}:alias/aws/ssm"
      ]
    }
  ]
}
EOF
}

# ECS
resource "aws_ecs_cluster" "web" {
  name = local.name
}
data "template_file" "ecs_task_web" {
  template = file("../modules/ecs/task.json")

  vars = {
    image     = var.image
    region    = var.region
    ENV       = var.env
    log_group = aws_cloudwatch_log_group.ecs_task_web.name
    command   = var.command
  }
}
# TaskDefinition
resource "aws_ecs_task_definition" "web" {
  family                   = local.name
  container_definitions    = data.template_file.ecs_task_web.rendered
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = data.aws_iam_role.ecs-task.arn
  cpu                      = 256
  memory                   = 512

  depends_on = [
    aws_cloudwatch_log_group.ecs_task_web
  ]
}
# SecurityGroup
resource "aws_security_group" "ecs" {
  name        = replace(local.name, "web", "ecs")
  description = "${var.env}_${var.service_name} ecs"
  vpc_id     = var.vpc_id

  # allow fron internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.service_name}-ecs"
  }
}
# SecurityGroupRule
resource "aws_security_group_rule" "ecs" {
  security_group_id = aws_security_group.ecs.id

  type      = "ingress"
  from_port = 80
  to_port   = 80
  protocol  = "tcp"

  cidr_blocks = [var.cidr]
}
# Service
resource "aws_ecs_service" "web" {
  name            = local.name
  cluster         = aws_ecs_cluster.web.id
  task_definition = aws_ecs_task_definition.web.arn
  launch_type     = "FARGATE"
  desired_count   = 0

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  scheduling_strategy                = "REPLICA"
  health_check_grace_period_seconds  = 300

  enable_ecs_managed_tags = true
  propagate_tags          = "SERVICE"

  network_configuration {
    security_groups  = [aws_security_group.ecs.id]
    subnets          = flatten(var.pri_ids)
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.lb_blue_id
    container_name   = basename(var.image)
    container_port   = 80
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  tags = {
    service = var.service_name
    env     = var.env
  }

  depends_on = [var.lb_listener]

  lifecycle {
    ignore_changes = [task_definition, load_balancer, desired_count]
  }
}
