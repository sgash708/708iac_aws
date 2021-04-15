# managed coding state
terraform {
  backend "s3" {
    bucket = "iac-code"
    key    = "ww9/state"
    region = "ap-northeast-1"
  }
  required_version = ">= 0.12"
}

#####################
# Provider(AWS)
#####################
provider "aws" {
  region = var.region
}
# if your region is 'us-east-1', please delete below provider.
provider "aws" {
  region = "us-east-1"
  alias  = "use1"
}

#####################
# DONE
#####################
# CodeCommit/ECR/CloudWatch/CodeBuild/CodePipeline
# S3 (for cloudfront's log)
data "aws_s3_bucket" "code" {
  bucket = "iac-code"
}
# Route53
data "aws_route53_zone" "apn1" {
  name         = var.domain_name
  private_zone = false
}
# ACM
data "aws_acm_certificate" "apn1" {
  provider = aws
  domain   = "*.${var.domain_name}"
}
# Route53(Global)
data "aws_route53_zone" "use1" {
  provider     = aws.use1
  name         = var.domain_name
  private_zone = false
}
# ACM
data "aws_acm_certificate" "use1" {
  provider = aws.use1
  domain   = "*.${var.domain_name}"
}

#####################
# Create
#####################
# VPC
module "vpc" {
  source = "../modules/vpc"

  service_name = "${var.env}-${var.service_name}"
  cidr         = var.vpc_cidr_block
  region       = var.region
}
# ALB
module "alb" {
  source = "../modules/alb"

  env          = var.env
  service_name = var.service_name
  vpc_id       = module.vpc.vpc_id
  pub_ids      = module.vpc.pub_ids
  acm_arn      = data.aws_acm_certificate.apn1.arn
  route53_id   = data.aws_route53_zone.apn1.id
  route53_name = data.aws_route53_zone.apn1.name
}
# ECS
module "ecs" {
  source = "../modules/ecs"

  env          = var.env
  service_name = var.service_name
  region       = var.region
  id           = var.id
  image        = var.image
  vpc_id       = module.vpc.vpc_id
  cidr         = var.vpc_cidr_block
  pri_ids      = module.vpc.pri_ids
  lb_blue_id   = module.alb.lb_target_blue_id
  lb_listener  = module.alb.lb_listener
  command      = var.ecs_command
}
# AutoScaling
module "autoscaling" {
  source = "../modules/autoscaling"

  ecs_cluster_name = module.ecs.cluster_name
  ecs_service_name = module.ecs.service_name
}