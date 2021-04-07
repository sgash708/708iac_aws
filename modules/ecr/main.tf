variable "service_name" {}
locals {
  name_list = ["${var.service_name}-base", "${var.service_name}-app"]
}

resource "aws_ecr_repository" "repos" {
  count = length(local.name_list)
  name  = local.name_list[count.index]
}

# delete untagged image
resource "aws_ecr_lifecycle_policy" "policies" {
  count      = length(local.name_list)
  repository = element(aws_ecr_repository.repos.*.name, count.index)

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire images older than 1 days",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 1
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}