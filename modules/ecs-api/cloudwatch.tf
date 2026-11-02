# See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-alarm-failure.html
resource "aws_cloudwatch_metric_alarm" "api_alb_5xx" {
  alarm_name          = "${var.service_name}-${var.environment}-api-alb-5xx"
  alarm_description   = "Roll back an API canary deployment when the ALB returns too many 5xx responses."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = var.api_alb_5xx_threshold
  treat_missing_data  = "notBreaching"

  metric_name = "HTTPCode_Target_5XX_Count"
  namespace   = "AWS/ApplicationELB"
  period      = 60
  statistic   = "Sum"

  dimensions = {
    LoadBalancer = aws_lb.api.arn_suffix
  }
}
