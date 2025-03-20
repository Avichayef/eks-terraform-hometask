# Add the AWS region data source
data "aws_region" "current" {}

# Monitoring Module Main Config
terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}

# Create monitoring namespace
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace
  }
}

# Deploy Prometheus Operator using kubectl
resource "kubectl_manifest" "prometheus_operator" {
  yaml_body = file("${path.module}/manifests/prometheus-operator.yaml")
  depends_on = [kubernetes_namespace.monitoring]
}

# Deploy Prometheus instance
resource "kubectl_manifest" "prometheus" {
  yaml_body = file("${path.module}/manifests/prometheus.yaml")
  depends_on = [kubectl_manifest.prometheus_operator]
}

# Deploy Grafana
resource "kubectl_manifest" "grafana" {
  yaml_body = templatefile("${path.module}/manifests/grafana.yaml", {
    admin_password = var.grafana_admin_password
    storage_size = var.grafana_storage_size
  })
  depends_on = [kubernetes_namespace.monitoring]
}

# Deploy ServiceMonitor for Flask app
resource "kubectl_manifest" "flask_servicemonitor" {
  yaml_body = <<YAML
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: flask-app
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: flask-app
  endpoints:
  - port: http
YAML
  depends_on = [kubectl_manifest.prometheus_operator]
}

# CloudWatch Agent Configuration
resource "kubernetes_config_map_v1" "cloudwatch_agent" {
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

  depends_on = [kubernetes_namespace.monitoring]
}

# CloudWatch Alarms
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
