output "ecs_cluster_name" {
  value = aws_ecs_cluster.web.name
}
output "ecs_service_name" {
  value = aws_ecs_service.web.name
}