output "base_repository_name" {
  value = aws_codecommit_repository.base.repository_name
}
output "app_repository_name" {
  value = aws_codecommit_repository.app.repository_name
}