provider "aws" {
  region = "${var.aws_region}"
}

data "template_file" "metricserver_userdata" {
  template = "metricserver.tpl"

  vars {
    admin_password  = "${var.admin_password}"
    grafana_port    = "${var.grafana_port}"
    influx_port     = "${var.influx_port}"
    influx_database = "${var.influx_database}"
  }
}

data "aws_ami" "windows" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["${var.windows_ami_filter}"]
  }
}

resource "aws_instance" "metricserver" {
  ami             = "${data.aws_ami.windows.id}"
  instance_type   = "${var.instance_type}"
  security_groups = ["${aws_security_group.metricserver_inbound.name}"]

  user_data = "${data.template_file.metricserver_userdata.rendered}"
}

resource "aws_security_group" "metricserver_inbound" {
  name        = "metricserver_inbound"
  description = "Allow inbound traffic to metricserver"

  ingress {
    from_port   = "${var.grafana_port}"
    to_port     = "${var.grafana_port}"
    protocol    = "tcp"
    cidr_blocks = ["${var.inbound_cidr_blocks}"]
  }

  ingress {
    from_port   = "${var.influx_port}"
    to_port     = "${var.influx_port}"
    protocol    = "tcp"
    cidr_blocks = ["${var.inbound_cidr_blocks}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
