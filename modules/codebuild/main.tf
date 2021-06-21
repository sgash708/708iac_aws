variable "repos_name" {}
variable "ecr_repos_name" {}
variable "region" {}
variable "id" {}
variable "service_name" {}

resource "aws_cloudwatch_log_group" "codebuild_logs" {
  count             = length(var.repos_name)
  name              = "/aws/codebuild/${var.repos_name[count.index]}"
  retention_in_days = 7
}
# just once
resource "aws_iam_role" "codebuild" {
  name               = "CodeBuildServiceRole"
  assume_role_policy = <<eof
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
eof
}
resource "aws_iam_role_policy_attachment" "codebuild" {
  role       = aws_iam_role.codebuild.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}
resource "aws_iam_role_policy" "codebuild" {
  name   = "CodeBuildServiceRolePolicy"
  role   = aws_iam_role.codebuild.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "codecommit:Gitpull",
        "ec2:Describe*",
        "ec2:CreateNetworkInterface",
        "ec2:CreateNetworkInterfacePermission",
        "ec2:DeleteNetworkInterface",
        "logs:CreategLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:PutObject"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}
resource "aws_codebuild_project" "applications" {
  count       = length(var.repos_name)
  name        = var.repos_name[count.index]
  description = "Building image for ${var.repos_name[count.index]}"

  service_role = aws_iam_role.codebuild.arn
  # 10minutes
  build_timeout = 10

  artifacts {
    type = "NO_ARTIFACTS"
  }

  # DockerCache
  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/docker:18.09.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.region
    }
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = var.id
    }
    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = var.ecr_repos_name[count.index]
    }
    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = "latest"
    }
  }
  source {
    type            = "CODECOMMIT"
    location        = "https://git-codecommit.ap-northeast-1.amazonaws.com/v1/repos/${var.repos_name[count.index]}"
    git_clone_depth = 1
  }

  tags = {
    service = var.service_name
  }
}