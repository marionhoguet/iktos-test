#Allow auto scaling on our cluster
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/iktos_cluster/iktos_service"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

#Define the autoscaling policies
resource "aws_appautoscaling_policy" "cpu_autoscaling" {
  name = "cpu_autoscaling"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    scale_in_cooldown = 60
    scale_out_cooldown = 60

    target_value = 20
  }
}

