output "grafana_url" {
  description = "URL for Grafana dashboard"
  value       = "http://${kubernetes_service.grafana[0].status[0].load_balancer[0].ingress[0].hostname}"
}

output "prometheus_url" {
  description = "URL for Prometheus"
  value       = "http://${kubernetes_service.prometheus[0].status[0].load_balancer[0].ingress[0].hostname}"
}

output "monitoring_sns_topic_arn" {
  description = "ARN of the SNS topic for monitoring alerts"
  value       = aws_sns_topic.monitoring_alerts.arn
}