output "lb_target_blue_id" {
  value = aws_lb_target_group.ecs-web[0].id
}
output "lb_target_blue_name" {
  value = aws_lb_target_group.ecs-web[0].name
}
output "lb_target_green_name" {
  value = aws_lb_target_group.ecs-web[1].name
}
output "lb_listener" {
  value = aws_lb_listener.web
}