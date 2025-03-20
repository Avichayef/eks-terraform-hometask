output "grafana_url" {
  value = "${aws_lb.main.dns_name}/grafana"
}

output "prometheus_url" {
  value = "${aws_lb.main.dns_name}/prometheus"
}
