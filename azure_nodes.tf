# Configure the Azure Provider
provider "azurerm" {
  subscription_id = "${lookup(var.azure_service_principal, "subscription_id")}"
  client_id       = "${lookup(var.azure_service_principal, "client_id")}"
  client_secret   = "${lookup(var.azure_service_principal, "client_secret")}"
  tenant_id       = "${lookup(var.azure_service_principal, "tenant_id")}"
  environment     = "${lookup(var.azure_service_principal, "environment")}"
}

# Create a resource group
resource "azurerm_resource_group" "resourcegroup" {
  name     = "${var.azure_resource_group}"
  location = "${var.azure_region}"
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "network" {
  name                = "${azurerm_resource_group.resourcegroup.name}-network"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name = "${azurerm_resource_group.resourcegroup.name}"
}

# Create a subnet
resource "azurerm_subnet" "subnet" {
  name                 = "${azurerm_resource_group.resourcegroup.name}-subnet"
  resource_group_name  = "${azurerm_resource_group.resourcegroup.name}"
  virtual_network_name = "${azurerm_virtual_network.network.name}"
  address_prefix       = "10.0.1.0/24"
}

# Create the network security group for the workers nodes
resource "azurerm_network_security_group" "nsg-workers" {
  name                = "${azurerm_resource_group.resourcegroup.name}-nsg-workers"
  location            = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name = "${azurerm_resource_group.resourcegroup.name}"

  security_rule {
    name                       = "RDP"
    description                = "Inboound-RDP"
    priority                   = 998
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "WinRM-HTTP"
    description                = "Inboound Windows Remote Management HTTP"
    priority                   = 999
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5985"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "WinRM-HTTPS"
    description                = "Inboound Windows Remote Management HTTPS"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5986"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH"
    description                = "Inbound SSH Traffic"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Canal-80"
    description                = "Inbound Canal Traffic"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Canal-443"
    description                = "Inbound Secure Canal Traffic"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "KubeletAPI"
    description                = "Inbound Kubelet API"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10250"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "kubeproxy"
    description                = "Inbound kubeproxy"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10256"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "NodePort-Services"
    description                = "Inbound services"
    priority                   = 1006
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30000-32767"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "worker_publicip" {
  count                        = "${var.windows_count}"
  name                         = "worker-publicIp-${count.index}"
  location                     = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name          = "${azurerm_resource_group.resourcegroup.name}"
  allocation_method = "Dynamic"
}

resource "azurerm_network_interface" "worker_nic" {
  count                     = "${var.windows_count}"
  name                      = "worker-nic-${count.index}"
  location                  = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name       = "${azurerm_resource_group.resourcegroup.name}"
  network_security_group_id = "${azurerm_network_security_group.nsg-workers.id}"

  ip_configuration {
    name                          = "worker-ip-configuration-${count.index}"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    public_ip_address_id          = "${element(azurerm_public_ip.worker_publicip.*.id, count.index)}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_managed_disk" "worker-disk" {
  count                = "${var.windows_count}"
  name                 = "worker-data-disk-${count.index}"
  location             = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name  = "${azurerm_resource_group.resourcegroup.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1023"
}

resource "azurerm_virtual_machine" "worker-machine" {
  count                            = "${var.windows_count}"
  name                             = "worker-${count.index}"
  location                         = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name              = "${azurerm_resource_group.resourcegroup.name}"
  network_interface_ids            = ["${element(azurerm_network_interface.worker_nic.*.id, count.index)}"]
  vm_size                          = "${var.windows_node_vm_size}"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true


  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServerSemiAnnual"
    sku       = "Datacenter-Core-1803-with-Containers-smalldisk"
    version   = "latest"
  }

  storage_os_disk {
    name              = "worker-os-disk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name            = "${element(azurerm_managed_disk.worker-disk.*.name, count.index)}"
    managed_disk_id = "${element(azurerm_managed_disk.worker-disk.*.id, count.index)}"
    create_option   = "Attach"
    lun             = 1
    disk_size_gb    = "${element(azurerm_managed_disk.worker-disk.*.disk_size_gb, count.index)}"
  }

  os_profile {
    computer_name  = "worker-${count.index}"
    admin_username = "${var.administrator_username}"
    admin_password = "${var.administrator_password}"
    custom_data    = "${file("./azure-boot/winrm.ps1")}"
  }

  os_profile_windows_config {
    provision_vm_agent = true
    winrm = {
      protocol = "http"
    }

    # Auto-Login's required to configure WinRM
    additional_unattend_config {
      pass         = "oobeSystem"
      component    = "Microsoft-Windows-Shell-Setup"
      setting_name = "AutoLogon"
      content      = "<AutoLogon><Password><Value>${var.administrator_username}</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>${var.administrator_password}</Username></AutoLogon>"
    }

    # Unattend config is to enable basic auth in WinRM, required for the provisioner stage.
    additional_unattend_config {
      pass         = "oobeSystem"
      component    = "Microsoft-Windows-Shell-Setup"
      setting_name = "FirstLogonCommands"
      content      = "${file("./azure-boot/FirstLogonCommands.xml")}"
    }
  }

  connection {
    type     = "winrm"
    port     = 5985
    https    = false
    timeout  = "2m"
    user     = "${var.administrator_username}"
    password = "${var.administrator_password}"
  }

  provisioner "remote-exec" {
    inline = [
      "${rancher2_cluster.windows-demo.cluster_registration_token.0.windows_node_command}"
    ]
  }
} 