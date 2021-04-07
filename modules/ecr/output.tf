output "ecr_repos_name" {
  value = aws_ecr_repository.repos.*.name
}