# Terraform-MetricStack

This repository contains Terraform code for deploying a single Windows 2016 Server in AWS with InfluxDB and Grafana installed as Windows Services and configured on default ports (configurable via variables), with those ports permitted from any internet address to the server.

Influx is a time-series database platform that can be used to store metrics. Grafana can be used to visualise those metrics via dashboards like these:

<p align="center">
<img src="http://wragg.io/content/images/2018/02/Grafana-Example-2.png" height=200>  <img src="http://wragg.io/content/images/2018/02/Grafana-TFS-Build-Dashboard.png" height=200>
</p>

## Prerequisites

- An Azure or AWS account (if you have Free Tier then the default settings of this stack should not incur any costs).
- An AWS Access Key created and configured on the machine you will be running Terraform (I suggest installing the AWS CLI and running `aws configure`).
- Terraform installed.

## Usage

1. Clone/download the code in this repository.
2. Open a terminal/shell and `cd` to either the AWS or Azure the directory.
3. Run `terraform init` to initialize/download plugins.
4. Run `terraform apply`. You will be prompted for `admin_password`, enter whatever you want the local machine admin password to be on the deployed instance. For Azure you will additionally be prompted for the ID of the subscription you want to deploy to.
5. Review the plan and enter `yes` (you should in particular be certain you're happy with the defaults that have been provided via `variables.tf`).
6. After a few minutes the deployment will complete and provide you with the Grafana and Influx URL, but on the default instance size (T2.micro) you will need to wait approximately 20 minutes for Grafana/Influx to be installed and ready.
7. When Grafana is ready, go to the URL provided for Grafana and log in with default credentials (admin / admin).
8. Add an Influx datasource with http://localhost:8086 as the URL and "metrics" as the databsase name (and a second one if you want to write metrics via UDP with the database named "udp".

By default a TCP and UDP listener will be enabled for Influx. Have a look at the official guide for how to write metrics to Influx, or you could install and use my [Influx PowerShell module](https://github.com/markwragg/PowerShell-Influx) to send metrics from anywhere where PowerShell is installed.

To use my PowerShell module (an example):

```
Install-Module Influx
Write-Influx -Server http://<youripaddress>:8086 -Measure YourMeasure -Metrics @{ CPU = 10; Memory = 50 } -database 'metrics'
```

Look at the official guidance for Grafana for how to visualise your metrics.

## Terraform Variables

The terraform code can be customised / defaults overrideen by adding the following variables to a file named `terraform.tfvars`:

- `admin_password` : The local admin password you want to set for the deployed Windows instance.
- `aws_region` : The AWS region to deploy to. Default: us-west-2
- `windows_ami_filter` : Use to modify the Windows AMI used for deployment. By default will deploy the latest Amazon Windows 2016 English Core Base AMI. If you want an OS with the desktop experience enabled, change "Core" to "Full" (beware this will negatively impact performance / speed of deployment for a T2.micro instance)
- `instance_type` : The EC2 instance type to deploy, T2.micro by default.
- `grafana_port` : The port for Grafana to listen on. Default: 8080
- `influx_port` : The port for the Influx REST API to listen on. Default: 8086
- `influx_databsase` : The database created by default for metrics from the REST API. Default: metrics
- `inbound_cidr_blocks` : The CIDR blocks to allow inbound connections to the server from (applies to all ports). Default: Internet/Any.
- `grafana_version` : The version of Grafana to install. Default: 5.3.2
- `influx_version` : The version of Influx to install. Default: 1.6.4
- `influx_udp_port` : The port for the Influx UDP listener to listen on (if enabled). Default: 8089
- `influx_udp_database` : The database created by default for metrcis from the UDP listener. Default: udp (you could make this the same as the REST API DB if you wanted to).
- `enable_rdp` : Boolean. Use to enable/disable an AWS SG Firewall rule so you can RDP to the server. Default: false (no rule for RDP is created).
- `enable_udp_listener` : Boolean. Use to enable/disable the UDP listener. Default: true (UDP listener is enabled).

## More Information

See these blog posts for more information:

- http://wragg.io/windows-based-grafana-analytics-platform-via-influxdb-and-powershell/
- http://wragg.io/deploying-an-influx-and-grafana-metrics-server-on-windows/
