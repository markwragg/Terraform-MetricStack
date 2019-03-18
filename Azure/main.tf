provider "azurerm" {
  subscription_id = "${var.subscription_id}"
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

data "azurerm_public_ip" "metricserver" {
  name                = "${azurerm_public_ip.metricserver.name}"
  resource_group_name = "${azurerm_resource_group.metricstack.name}"
  depends_on          = ["azurerm_virtual_machine.metricserver"]
}

resource "azurerm_resource_group" "metricstack" {
  name     = "MetricStack"
  location = "${var.azure_region}"
}

resource "azurerm_virtual_network" "metricstack" {
  name                = "${var.prefix}-network"
  address_space       = "${var.vnet_address_space}"
  location            = "${azurerm_resource_group.metricstack.location}"
  resource_group_name = "${azurerm_resource_group.metricstack.name}"
}

resource "azurerm_subnet" "metricstack" {
  name                      = "internal"
  resource_group_name       = "${azurerm_resource_group.metricstack.name}"
  virtual_network_name      = "${azurerm_virtual_network.metricstack.name}"
  address_prefix            = "${var.private_subnet_address_prefix}"
  network_security_group_id = "${azurerm_network_security_group.metricserver_inbound.id}"
}

resource "azurerm_network_interface" "metricserver" {
  name                = "${var.prefix}-nic"
  location            = "${azurerm_resource_group.metricstack.location}"
  resource_group_name = "${azurerm_resource_group.metricstack.name}"

  ip_configuration {
    name                          = "${var.prefix}-configuration1"
    subnet_id                     = "${azurerm_subnet.metricstack.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.metricserver.id}"
  }
}

resource "azurerm_public_ip" "metricserver" {
  name                = "${var.prefix}-PublicIp"
  location            = "${azurerm_resource_group.metricstack.location}"
  resource_group_name = "${azurerm_resource_group.metricstack.name}"
  allocation_method   = "Dynamic"

  tags = {
    environment = "Production"
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

  os_profile_windows_config {
    provision_vm_agent = true
  }
}

resource "azurerm_virtual_machine_extension" "metricserver" {
  name                 = "metricserver"
  location             = "${azurerm_resource_group.metricstack.location}"
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

resource "azurerm_network_security_group" "metricserver_inbound" {
  name                = "metricserver_inbound"
  location            = "${azurerm_resource_group.metricstack.location}"
  resource_group_name = "${azurerm_resource_group.metricstack.name}"
}

resource "azurerm_subnet_network_security_group_association" "metricstack" {
  subnet_id                 = "${azurerm_subnet.metricstack.id}"
  network_security_group_id = "${azurerm_network_security_group.metricserver_inbound.id}"
}

resource "azurerm_network_security_rule" "influx" {
  name                        = "influx"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "${var.influx_port}"
  source_address_prefixes     = ["${var.inbound_cidr_blocks}"]
  destination_address_prefix  = "${azurerm_network_interface.metricserver.private_ip_address}"
  resource_group_name         = "${azurerm_resource_group.metricstack.name}"
  network_security_group_name = "${azurerm_network_security_group.metricserver_inbound.name}"
}

resource "azurerm_network_security_rule" "grafana" {
  name                        = "grafana"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "${var.grafana_port}"
  source_address_prefixes     = ["${var.inbound_cidr_blocks}"]
  destination_address_prefix  = "${azurerm_network_interface.metricserver.private_ip_address}"
  resource_group_name         = "${azurerm_resource_group.metricstack.name}"
  network_security_group_name = "${azurerm_network_security_group.metricserver_inbound.name}"
}

resource "azurerm_network_security_rule" "udp_listener" {
  count                       = "${var.enable_udp_listener ? 1 : 0}"
  name                        = "udp_listener"
  priority                    = 300
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range           = "*"
  destination_port_range      = "${var.influx_udp_port}"
  source_address_prefixes     = ["${var.inbound_cidr_blocks}"]
  destination_address_prefix  = "${azurerm_network_interface.metricserver.private_ip_address}"
  resource_group_name         = "${azurerm_resource_group.metricstack.name}"
  network_security_group_name = "${azurerm_network_security_group.metricserver_inbound.name}"
}

resource "azurerm_network_security_rule" "rdp" {
  count                       = "${var.enable_rdp ? 1 : 0}"
  name                        = "rdp"
  priority                    = 500
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = 3389
  source_address_prefixes     = ["${var.inbound_cidr_blocks}"]
  destination_address_prefix  = "${azurerm_network_interface.metricserver.private_ip_address}"
  resource_group_name         = "${azurerm_resource_group.metricstack.name}"
  network_security_group_name = "${azurerm_network_security_group.metricserver_inbound.name}"
}
