output "codebuild_apps_name" {
  value = aws_codebuild_project.applications.*.name
}