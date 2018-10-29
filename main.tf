provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

data "aws_ami" "windows" {
  most_recent = true

  filter {
    name   = "name"
    values = ["Windows_Server-2016-English-Full-Base*"]
  }

  owners = ["amazon"]
}

resource "aws_instance" "metricserver" {
  ami               = "${data.aws_ami.windows.id}"
  instance_type     = "${var.instance_type}"
  key_name          = "${var.key_name}"
  get_password_data = true
  security_groups   = ["${aws_security_group.metricserver_inbound.name}"]

  user_data = <<EOF
    <script>
      @powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
    </script>
    <powershell>
      #Install non-sucking service manager
      choco install -y nssm
      
      #Install Grafana
      Set-Location C:\
      Invoke-WebRequest https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana-5.3.2.windows-amd64.zip -OutFile Grafana.zip
      Expand-Archive C:\Grafana.zip
      Get-Item C:\Grafana\Grafana* | Rename-Item -NewName Grafana
      $Defaults = 'C:\Grafana\Grafana\conf\defaults.ini'
      (Get-Content $Defaults) -Replace 'http_port = 3000','http_port=${var.grafana_port}' | Set-Content $Defaults
      New-NetFirewallRule -DisplayName "Grafana" -Direction Inbound -Action Allow -LocalPort ${var.grafana_port} -Protocol TCP
      nssm install Grafana "C:\Grafana\Grafana\bin\grafana-server.exe" 
      Start-Service Grafana

      #Install Influx
      Set-Location C:\
      Invoke-WebRequest https://dl.influxdata.com/influxdb/releases/influxdb-1.6.4_windows_amd64.zip -OutFile Influx.zip
      Expand-Archive C:\Influx.zip
      Get-Item C:\Influx\InfluxDB* | Rename-Item -NewName InfluxDB
      New-NetFirewallRule -DisplayName "Influx" -Direction Inbound -Action Allow -LocalPort ${var.influx_port} -Protocol TCP
      nssm install InfluxDB "C:\Influx\InfluxDB\influxd.exe"
      Start-Service InfluxDB
      C:\Influx\InfluxDB\influx.exe -execute 'CREATE DATABASE ${var.influx_database}'
    </powershell>
    EOF
}
resource "aws_security_group" "metricserver_inbound" {
  name        = "metricserver_inbound"
  description = "Allow inbound traffic to metricserver"

  ingress {
    from_port   = "${var.grafana_port}"
    to_port     = "${var.grafana_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = "${var.influx_port}"
    to_port     = "${var.influx_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}