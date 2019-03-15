output "grafana_url" {
  value = "http://${aws_instance.metricserver.public_ip}:${var.grafana_port}"
}

output "influx_url" {
  value = "http://${aws_instance.metricserver.public_ip}:${var.influx_port}"
}
