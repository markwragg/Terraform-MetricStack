#AWS
variable "access_key" {}
variable "secret_key" {}
variable "region" {
  default = "us-west-2"
}

variable "instance_type" {
  default = "t2.micro"
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