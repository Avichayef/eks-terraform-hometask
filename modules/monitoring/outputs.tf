output "grafana_url" {
  description = "Grafana URL"
  value       = "http://localhost:3000"  # Default local access via port-forward
}

output "prometheus_url" {
  description = "Prometheus URL"
  value       = "http://localhost:9090"  # Default local access via port-forward
}

output "monitoring_namespace" {
  description = "Kubernetes namespace for monitoring"
  value       = var.namespace
}
