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