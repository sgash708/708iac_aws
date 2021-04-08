# managed coding state
terraform {
  backend "s3" {
    bucket = "iac-code"
    key    = "common/state"
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
# Create
#####################
# CodeCommit
module "codecommit" {
  source       = "../modules/codecommit"
  service_name = var.service_name
}
# ECR
module "ecr" {
  source       = "../modules/ecr"
  service_name = var.service_name
}
# CodeBuild
module "codebuild" {
  source = "../modules/codebuild"

  repos_name     = module.codecommit.repositories_name
  ecr_repos_name = module.ecr.ecr_repos_name
  region         = var.region
  id             = var.id
  service_name   = var.service_name
}
# S3
module "s3" {
  source = "../modules/s3"

  service_name = var.service_name
}