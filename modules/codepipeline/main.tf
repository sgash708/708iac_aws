variable "service_name" {}
variable "s3bucket" {}
variable "repos_name" {}
variable "codebuild_apps_name" {}
locals {
  # automatic deploy(ww9)
  name = format("%s-%s-%s", "ww9", var.service_name, "web")
}

resource "aws_iam_role" "codepipeline" {
  name = "CodePipelineServiceRole"
  assume_role_policy = <<eof
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "",
        "Effect": "Allow",
        "Principal": {
          "Service": "codepipeline.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
}
eof
}
resource "aws_iam_role_policy" "codepipeline-default" {
  name = "CodePipelineServiceRoleDefaultPolicy"
  role = aws_iam_role.codepipeline.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning"
      ],
      "Resource": "*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::codepipeline*",
        "arn:aws:s3:::elasticbeanstalk*"
      ],
      "Effect": "Allow"
    },
    {
      "Action": [
        "codedeploy:CreateDeployment",
        "codedeploy:GetApplication",
        "codedeploy:GetApplicationRevision",
        "codedeploy:GetDeployment",
        "codedeploy:GetDeploymentConfig",
        "codedeploy:RegisterApplicationRevision",
        "ecs:RegisterTaskDefinition",
        "iam:PassRole"
      ],
      "Resource": "*",
      "Effect": "Allow"
    },
    {
    "Action": [
        "elasticbeantalk:CreateApplicationVersion",
        "elasticbeantalk:DescribeApplicationVersions",
        "elasticbeantalk:DescribeEnvironments",
        "elasticbeantalk:DescribeEvents",
        "elasticbeantalk:UpdateEnvironment",

        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeScalingActivities",
        "autoscaling:ResumeProcesses",

        "cloudformation:DescribeStackResource",
        "cloudformation:DescribeStackResources",
        "cloudformation:DescriveStackEvents",
        "cloudformation:DescribeStacks",
        "cloudformation:UpdateStack",

        "ec2:DescribeInstances",
        "ec2:DescribeImages",
        "ec2:DescribeAddresses",
        "ec2:DescribeSubnets",
        "ec2:DescribeVpcs",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeKeyPairs",

        "elasticloadbalancing:DescribeLoadBalancers",

        "rds:DescribeDBInstances",
        "rds:DescribeOrderableDBInstanceOptions",

        "sns:ListSubscriptionsByTopic"
      ],
      "Resource": "*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "lambda:invokefunction",
        "lambda:listfunction"
      ],
      "Resource": "*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketPolicy",
        "s3:GetObjectAcl",
        "s3:PutObjectAcl",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::elasticbeanstalk*",
      "Effect": "Allow"
    }
  ]
}
EOF
}
# add custom policy
resource "aws_iam_role_policy" "codepipeline-custom" {
  name = "CodePipelineServiceRoleCustomPolicy"
  role = aws_iam_role.codepipeline.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "arn:aws:s3:::${var.s3bucket}/",
        "arn:aws:s3:::${var.s3bucket}/*"
      ],
      "Effect": "Allow"
    },
    {
      "Action": [
        "codecommit:GetBranch",
        "codecommit:GetCommit",
        "codecommit:UploadArchive",
        "codecommit:GetUploadArchiveStatus",
        "codecommit:CancelUploadArchive"
      ],
      "Resource": "*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "ecr:DescribeImages"
      ],
      "Resource": "*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "ecs:DescribeServices",
        "ecs:DescribeTaskDifinition",
        "ecs:DescribeTasks",
        "ecs:ListTasks",
        "ecs:RegisterTaskDefinition",
        "ecs:UpdateService"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF
}
# base
resource "aws_codepipeline" "base" {
  name     = var.repos_name[0]
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    type     = "S3"
    location = var.s3bucket
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source"]
      # master branch's source
      configuration = {
        RepositoryName = var.repos_name[0]
        BranchName     = "master"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source"]

      configuration = {
        ProjectName = var.codebuild_apps_name[0]
      }
    }
  }
}
# app
resource "aws_codepipeline" "app" {
  name     = var.repos_name[1]
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    type = "S3"
    location = var.s3bucket
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source"]
      configuration = {
        RepositoryName = var.repos_name[1]
        BranchName     = "master"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source"]

      configuration = {
        ProjectName = var.codebuild_apps_name[1]
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      version         = "1"
      input_artifacts = ["build"]

      configuration = {
        ApplicationName                = "${local.name}_ecs"
        DeploymentGroupName            = local.name
        TaskDefinitionTemplateArtifact = "build"
        TaskDefinitionTemplatePath     = "taskdef.json"
        AppSpecTemplateArtifact        = "build"
        AppSpecTemplatePath            = "appspec.yml"
        Image1ArtifactName             = "build"
        Image1ContainerName            = "IMAGE1_NAME"
      }
    }
  }
}