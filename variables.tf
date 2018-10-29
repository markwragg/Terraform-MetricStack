#AWS
variable "access_key" {}
variable "secret_key" {}
variable "admin_password" {}

variable "aws_region" {
  default = "us-west-2"
}

variable "windows_ami_filter" {
  default = "Windows_Server-2016-English-Core-Base*"
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
