output "grafana_url" {
  value = "http://${azurerm_public_ip.metricserver.ip_address}:${var.grafana_port}"
}

output "influx_url" {
  value = "http://${azurerm_public_ip.metricserver.ip_address}:${var.influx_port}"
}
