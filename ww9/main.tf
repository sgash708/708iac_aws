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
# Create
#####################
