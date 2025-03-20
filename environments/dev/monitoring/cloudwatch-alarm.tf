resource "aws_cloudwatch_metric_alarm" "flask_5xx_errors" {
  alarm_name          = "flask-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name        = "5xx_error_count"
  namespace          = "AWS/ApplicationELB"
  period             = "300"
  statistic          = "Sum"
  threshold          = "10"
  alarm_description  = "This metric monitors flask app 5xx errors"
  alarm_actions      = [aws_sns_topic.flask_alerts.arn]

  dimensions = {
    LoadBalancer = aws_lb.flask_app.name
  }
}

resource "aws_sns_topic" "flask_alerts" {
  name = "flask-alerts"
}