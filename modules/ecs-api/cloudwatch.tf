# See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-alarm-failure.html
# See https://stackharbor.com/en/knowledge-base/awsdeploy-rollback-automation-cloudwatch
# See https://web-alert.io/blog/5xx-server-error-rate-monitoring-alerting-guide
# 低流量使用 5xx 數量，高流量使用 5xx 比例
resource "aws_cloudwatch_metric_alarm" "api_alb_5xx" {
  alarm_name          = "${var.service_name}-${var.environment}-api-target-5xx-rate"
  alarm_description   = "Roll back an API canary deployment when target 5xx responses on the ALB reach 1% for two minutes."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  threshold           = 1
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "target_5xx"
    return_data = false

    metric {
      metric_name = "HTTPCode_Target_5XX_Count"
      namespace   = "AWS/ApplicationELB"
      period      = 60
      stat        = "Sum"

      dimensions = {
        LoadBalancer = aws_lb.api.arn_suffix
      }
    }
  }

  metric_query {
    id          = "requests"
    return_data = false

    metric {
      metric_name = "RequestCount"
      namespace   = "AWS/ApplicationELB"
      period      = 60
      stat        = "Sum"

      dimensions = {
        LoadBalancer = aws_lb.api.arn_suffix
      }
    }
  }

  metric_query {
    id          = "error_rate"
    label       = "Target 5xx response rate (%)"
    expression  = "IF(requests > 0, 100 * target_5xx / requests, 0)"
    return_data = true
  }
}
