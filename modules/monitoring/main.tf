# Add the AWS region data source
data "aws_region" "current" {}

# Monitoring Module Main Config
# Sets up complete monitoring stack using Helm and Terraform

# Create monitoring namespace
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace
  }
}

# Deploy Prometheus Stack using Helm
resource "helm_release" "prometheus_stack" {
  name       = "prometheus"
  namespace  = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "70.1.1"

  # Increase timeout to 15 minutes
  timeout = 900

  # Add creation of CRDs first
  create_namespace = true
  skip_crds       = false

  values = [
    templatefile("${path.module}/templates/prometheus-values.yaml", {
      sns_topic_arn = aws_sns_topic.monitoring_alerts.arn
    })
  ]

  depends_on = [
    kubernetes_namespace.monitoring
  ]
}

# CloudWatch Agent Configuration
resource "kubernetes_config_map" "cloudwatch_agent" {
  count = var.enable_cloudwatch ? 1 : 0

  metadata {
    name      = "cloudwatch-agent-config"
    namespace = var.namespace
  }

  data = {
    "cwagentconfig.json" = templatefile("${path.module}/templates/cloudwatch-config.json", {
      cluster_name = var.cluster_name
      region      = data.aws_region.current.name
    })
  }

  depends_on = [
    kubernetes_namespace.monitoring
  ]
}

# CloudWatch Alarms - Only create if ALB ARN is provided
resource "aws_cloudwatch_metric_alarm" "flask_5xx_errors" {
  count = var.alb_arn != null ? 1 : 0

  alarm_name          = "${var.environment}-flask-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name        = "HTTPCode_Target_5XX_Count"
  namespace          = "AWS/ApplicationELB"
  period             = "300"
  statistic          = "Sum"
  threshold          = "10"
  alarm_description  = "This metric monitors flask app 5xx errors"
  alarm_actions      = [aws_sns_topic.monitoring_alerts.arn]

  dimensions = {
    LoadBalancer = var.alb_arn
  }
}

# SNS Topic for Alerts
resource "aws_sns_topic" "monitoring_alerts" {
  name = "${var.environment}-monitoring-alerts"
}
