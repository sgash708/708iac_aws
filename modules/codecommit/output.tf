output "repositories_name" {
  value = [aws_codecommit_repository.repos.*.repository_name]
}