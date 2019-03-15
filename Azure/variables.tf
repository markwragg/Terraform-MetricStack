variable "prefix" {
  default = "metricstack"
}

variable "admin_password" {}

variable "azure_region" {
  default = "West US"
}

variable "grafana_port" {
  default = 8080
}

variable "influx_port" {
  default = 8086
}

variable "influx_database" {
  default = "metrics"
}

variable "inbound_cidr_blocks" {
  default = ["0.0.0.0/0"]
}

variable "grafana_version" {
  default = "5.3.2"
}

variable "influx_version" {
  default = "1.6.4"
}

variable "influx_udp_port" {
  default = 8089
}

variable "influx_udp_database" {
  default = "udp"
}

variable "enable_rdp" {
  default = false
}

variable "enable_udp_listener" {
  default = true
}