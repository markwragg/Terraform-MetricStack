provider "aws" {
  region = "${var.aws_region}"
}

data "template_file" "metricserver" {
  template = "${file("metricserver.tpl")}"

  vars {
    admin_password      = "${var.admin_password}"
    grafana_port        = "${var.grafana_port}"
    grafana_version     = "${var.grafana_version}"
    influx_port         = "${var.influx_port}"
    influx_database     = "${var.influx_database}"
    influx_version      = "${var.influx_version}"
    influx_udp_port     = "${var.influx_udp_port}"
    influx_udp_database = "${var.influx_udp_database}"
    enable_udp_listener = "${var.enable_udp_listener}"
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

  user_data = "${data.template_file.metricserver.rendered}"
}

resource "aws_security_group" "metricserver_inbound" {
  name        = "metricserver_inbound"
  description = "Allow inbound traffic to metricserver"
}

resource "aws_security_group_rule" "influx" {
  type              = "ingress"
  from_port         = "${var.influx_port}"
  to_port           = "${var.influx_port}"
  protocol          = "tcp"
  cidr_blocks       = ["${var.inbound_cidr_blocks}"]
  security_group_id = "${aws_security_group.metricserver_inbound.id}"
}

resource "aws_security_group_rule" "grafana" {
  type              = "ingress"
  from_port         = "${var.grafana_port}"
  to_port           = "${var.grafana_port}"
  protocol          = "tcp"
  cidr_blocks       = ["${var.inbound_cidr_blocks}"]
  security_group_id = "${aws_security_group.metricserver_inbound.id}"
}

resource "aws_security_group_rule" "rdp" {
  count             = "${var.enable_rdp ? 1 : 0}"
  type              = "ingress"
  from_port         = 3389
  to_port           = 3389
  protocol          = "tcp"
  cidr_blocks       = ["${var.inbound_cidr_blocks}"]
  security_group_id = "${aws_security_group.metricserver_inbound.id}"
}

resource "aws_security_group_rule" "udp_listener" {
  count             = "${var.enable_udp_listener ? 1 : 0}"
  type              = "ingress"
  from_port         = "${var.influx_udp_port}"
  to_port           = "${var.influx_udp_port}"
  protocol          = "udp"
  cidr_blocks       = ["${var.inbound_cidr_blocks}"]
  security_group_id = "${aws_security_group.metricserver_inbound.id}"
}

resource "aws_security_group_rule" "default_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.metricserver_inbound.id}"
}
