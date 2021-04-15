variable "ecs_cluster_name" {}
variable "ecs_service_name" {}

resource "aws_appautoscaling_target" "ecs" {
  min_capacity       = 1
  max_capacity       = 6
  resource_id        = "service/${var.ecs_cluster_name}/${var.ecs_service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  lifecycle {
    ignore_changes = [min_capacity, max_capacity]
  }
}
resource "aws_appautoscaling_policy" "ecs" {
  name = "ECSServiceAverageCPUUtilization:${aws_appautoscaling_target.ecs.resource_id}"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 50
    scale_out_cooldown = 100
    scale_in_cooldown  = 300
  }
}