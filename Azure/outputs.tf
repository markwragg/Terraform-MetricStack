output "grafana_url" {
  value = "http://tbc:${var.grafana_port}"
}

output "influx_url" {
  value = "http://tbc:${var.influx_port}"
}
