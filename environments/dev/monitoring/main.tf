# Monitoring Infrastructure Config
# This Terraform configuration sets up CloudWatch alarms and SNS topics for monitoring

# SNS Topic for alerts
resource "aws_sns_topic" "flask_alerts" {
  name = "flask-alerts"
  tags = {
    Environment = "dev"
    Application = "flask-app"
  }
}

# CloudWatch Alarm for 5xx errors
resource "aws_cloudwatch_metric_alarm" "flask_5xx_errors" {
  alarm_name          = "flask-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name        = "HTTPCode_Target_5XX_Count"
  namespace          = "AWS/ApplicationELB"
  period             = "300"
  statistic          = "Sum"
  threshold          = "10"
  alarm_description  = "This metric monitors flask app 5xx errors"
  alarm_actions      = [aws_sns_topic.flask_alerts.arn]

  dimensions = {
    LoadBalancer = var.alb_arn
  }

  tags = {
    Environment = "dev"
    Application = "flask-app"
  }
}

# CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "flask_cpu_high" {
  alarm_name          = "flask-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name        = "cpu_utilization"
  namespace          = "AWS/ECS"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "This metric monitors flask app CPU utilization"
  alarm_actions      = [aws_sns_topic.flask_alerts.arn]

  dimensions = {
    ClusterName = var.eks_cluster_name
    ServiceName = "flask-app"
  }

  tags = {
    Environment = "dev"
    Application = "flask-app"
  }
}