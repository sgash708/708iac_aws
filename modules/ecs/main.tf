variable "env" {}
variable "service_name" {}
variable "region" {}
variable "id" {}
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
  vpc_fid     = var.vpc_id

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