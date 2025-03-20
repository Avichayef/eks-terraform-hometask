# Add the AWS region data source
data "aws_region" "current" {}

# Monitoring Module Main Config
# Sets up complete monitoring stack using Helm and Terraform

# Create monitoring namespace if it doesn't exist
resource "null_resource" "monitoring_namespace" {
  provisioner "local-exec" {
    command = "kubectl create namespace ${var.namespace} --dry-run=client -o yaml | kubectl apply -f -"
  }
}

# Deploy Prometheus Stack using Helm
resource "helm_release" "prometheus" {
  name       = "prometheus"
  namespace  = var.namespace
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "70.1.1"

  # Increase timeout to 20 minutes
  timeout = 1200

  # Add retry logic
  recreate_pods = true
  force_update  = true
  cleanup_on_fail = true

  create_namespace = false
  skip_crds       = false

  values = [
    templatefile("${path.module}/templates/prometheus-values.yaml", {
      sns_topic_arn = aws_sns_topic.monitoring_alerts.arn
      retention_period = var.prometheus_retention_period
      cpu_request = var.prometheus_cpu_request
      memory_request = var.prometheus_memory_request
      cpu_limit = var.prometheus_cpu_limit
      memory_limit = var.prometheus_memory_limit
      storage_size = var.prometheus_storage_size
      admin_password = var.grafana_admin_password
      grafana_storage = var.grafana_storage_size
    })
  ]

  # Add wait for CRDs to be ready
  provisioner "local-exec" {
    command = "kubectl wait --for=condition=Established crd/prometheuses.monitoring.coreos.com crd/alertmanagers.monitoring.coreos.com --timeout=300s"
  }

  depends_on = [
    null_resource.monitoring_namespace
  ]
}

# CloudWatch Agent Configuration
resource "kubernetes_config_map_v1" "cloudwatch_agent" {  # Changed to v1 version
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
    null_resource.monitoring_namespace
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
