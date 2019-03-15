provider "azurerm" {
  subscription_id = "5b638ecc-c05a-4d62-b152-4898379da0d3"

  # client_id       = "REPLACE-WITH-YOUR-CLIENT-ID"
  # client_secret   = "REPLACE-WITH-YOUR-CLIENT-SECRET"
  # tenant_id       = "REPLACE-WITH-YOUR-TENANT-ID"
}

data "template_file" "metricserver" {
  template = "${file("CustomData.tpl")}"

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

resource "azurerm_resource_group" "metricstack" {
  name     = "MetricStack"
  location = "${var.azure_region}"
}

resource "azurerm_virtual_network" "metricstack" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.metricstack.location}"
  resource_group_name = "${azurerm_resource_group.metricstack.name}"
}

resource "azurerm_subnet" "metricstack" {
  name                 = "internal"
  resource_group_name  = "${azurerm_resource_group.metricstack.name}"
  virtual_network_name = "${azurerm_virtual_network.metricstack.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_network_interface" "metricserver" {
  name                = "${var.prefix}-nic"
  location            = "${azurerm_resource_group.metricstack.location}"
  resource_group_name = "${azurerm_resource_group.metricstack.name}"

  ip_configuration {
    name                          = "${var.prefix}-configuration1"
    subnet_id                     = "${azurerm_subnet.metricstack.id}"
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "metricserver" {
  name                             = "${var.prefix}-vm"
  location                         = "${azurerm_resource_group.metricstack.location}"
  resource_group_name              = "${azurerm_resource_group.metricstack.name}"
  network_interface_ids            = ["${azurerm_network_interface.metricserver.id}"]
  vm_size                          = "Standard_DS1_v2"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter-Core"
    version   = "latest"
  }

  storage_os_disk {
    name              = "metricserver-osdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "metricserver"
    admin_username = "metricadmin"
    admin_password = "${var.admin_password}"
    custom_data    = "${data.template_file.metricserver.rendered}"
  }
  os_profile_windows_config {}
}

resource "azurerm_virtual_machine_extension" "metricserver" {
  name                 = "metricserver"
  location             = "West US"
  resource_group_name  = "${azurerm_resource_group.metricstack.name}"
  virtual_machine_name = "${azurerm_virtual_machine.metricserver.name}"
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.8"

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell -command copy-item \"c:\\AzureData\\CustomData.bin\" \"c:\\AzureData\\CustomData.ps1\";\"c:\\AzureData\\CustomData.ps1\""
    }
SETTINGS
}
