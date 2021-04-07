variable "service_name" {}
locals {
  name = "${var.service_name}-image"
}

resource "aws_codecommit_repository" "app" {
  repository_name = "${local.name}-base"
  description     = "base image code"
}
resource "aws_codecommit_repository" "base" {
  repository_name = "${local.name}-app"
  description     = "app image code"
}