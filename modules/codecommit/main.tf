variable "service_name" {}
locals {
  name_list = ["${var.service_name}-image-base", "${var.service_name}-image-app"]
}

resource "aws_codecommit_repository" "repos" {
  count           = length(local.name_list)
  repository_name = local.name_list[count.index]
  description     = "${local.name_list[count.index]} repository"
}