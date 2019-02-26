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

# Create the network security group for the control plane nodes
resource "azurerm_network_security_group" "nsg-controlplane" {
  name                = "${azurerm_resource_group.resourcegroup.name}-nsg-controlplane"
  location            = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name = "${azurerm_resource_group.resourcegroup.name}"

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
    name                       = "KubernetesAPIServer"
    description                = "Inbound Kubenetes API"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "etcd"
    description                = "Inbound etcd"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2379-2380"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "KubeletAPI"
    description                = "Inbound Kubelet API"
    priority                   = 1006
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10250"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "KubernetesScheduler"
    description                = "Inbound Kubernetes Scheduler"
    priority                   = 1007
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10251"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "KubernetesController"
    description                = "Inbound Kubernetes Controller"
    priority                   = 1008
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10252"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "kubeproxy"
    description                = "Inbound Kubernetes kubeproxy"
    priority                   = 1009
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10256"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create the network security group for the etcd nodes
resource "azurerm_network_security_group" "nsg-etcd" {
  name                = "${azurerm_resource_group.resourcegroup.name}-nsg-etcd"
  location            = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name = "${azurerm_resource_group.resourcegroup.name}"

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
    name                       = "KubernetesAPI"
    description                = "Inbound Kubenetes API"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "etcd"
    description                = "Inbound etcd"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2379-2380"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "KubeletAPI"
    description                = "Inbound Kubelet API"
    priority                   = 1006
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10250"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "KubernetesScheduler"
    description                = "Inbound Kubernetes Scheduler"
    priority                   = 1007
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10251"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "KubernetesController"
    description                = "Inbound Kubernetes Controller"
    priority                   = 1008
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10252"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "kubeproxy"
    description                = "Inbound Kubernetes kubeproxy"
    priority                   = 1009
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10256"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "worker_publicip" {
  count                        = "${var.rke_worker_count}"
  name                         = "worker-publicIp-${count.index}"
  location                     = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name          = "${azurerm_resource_group.resourcegroup.name}"
  public_ip_address_allocation = "dynamic"
}

resource "azurerm_public_ip" "controlplane_publicip" {
  count                        = "${var.rke_controlplane_count}"
  name                         = "controlplane-publicIp-${count.index}"
  location                     = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name          = "${azurerm_resource_group.resourcegroup.name}"
  public_ip_address_allocation = "dynamic"
}

resource "azurerm_public_ip" "etcd_publicip" {
  count                        = "${var.rke_etcd_count}"
  name                         = "etcd-publicIp-${count.index}"
  location                     = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name          = "${azurerm_resource_group.resourcegroup.name}"
  public_ip_address_allocation = "dynamic"
}

resource "azurerm_network_interface" "worker_nic" {
  count                     = "${var.rke_worker_count}"
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

resource "azurerm_network_interface" "controlplane_nic" {
  count                     = "${var.rke_controlplane_count}"
  name                      = "controlplane-nic-${count.index}"
  location                  = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name       = "${azurerm_resource_group.resourcegroup.name}"
  network_security_group_id = "${azurerm_network_security_group.nsg-controlplane.id}"

  ip_configuration {
    name                          = "controlplane-ip-configuration-${count.index}"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    public_ip_address_id          = "${element(azurerm_public_ip.controlplane_publicip.*.id, count.index)}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_network_interface" "etcd_nic" {
  count                     = "${var.rke_etcd_count}"
  name                      = "etcd-nic-${count.index}"
  location                  = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name       = "${azurerm_resource_group.resourcegroup.name}"
  network_security_group_id = "${azurerm_network_security_group.nsg-etcd.id}"

  ip_configuration {
    name                          = "etcd-ip-configuration-${count.index}"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    public_ip_address_id          = "${element(azurerm_public_ip.etcd_publicip.*.id, count.index)}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_managed_disk" "worker-disk" {
  count                = "${var.rke_worker_count}"
  name                 = "worker-data-disk-${count.index}"
  location             = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name  = "${azurerm_resource_group.resourcegroup.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1023"
}

resource "azurerm_managed_disk" "controlplane-disk" {
  count                = "${var.rke_controlplane_count}"
  name                 = "controlplane-data-disk-${count.index}"
  location             = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name  = "${azurerm_resource_group.resourcegroup.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1023"
}

resource "azurerm_managed_disk" "etcd-disk" {
  count                = "${var.rke_etcd_count}"
  name                 = "etcd-data-disk-${count.index}"
  location             = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name  = "${azurerm_resource_group.resourcegroup.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1023"
}

resource "azurerm_virtual_machine" "worker-machine" {
  count                            = "${var.rke_worker_count}"
  name                             = "worker-${count.index}"
  location                         = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name              = "${azurerm_resource_group.resourcegroup.name}"
  network_interface_ids            = ["${element(azurerm_network_interface.worker_nic.*.id, count.index)}"]
  vm_size                          = "${var.worker_node_vm_size}"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
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
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.administrator_username}/.ssh/authorized_keys"
      key_data = "${var.administrator_ssh}"
    }
  }
}

resource "azurerm_virtual_machine" "controlplane-machine" {
  count                            = "${var.rke_controlplane_count}"
  name                             = "controlplane-${count.index}"
  location                         = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name              = "${azurerm_resource_group.resourcegroup.name}"
  network_interface_ids            = ["${element(azurerm_network_interface.controlplane_nic.*.id, count.index)}"]
  vm_size                          = "${var.controlplane_node_vm_size}"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "controlplane-os-disk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name            = "${element(azurerm_managed_disk.controlplane-disk.*.name, count.index)}"
    managed_disk_id = "${element(azurerm_managed_disk.controlplane-disk.*.id, count.index)}"
    create_option   = "Attach"
    lun             = 1
    disk_size_gb    = "${element(azurerm_managed_disk.controlplane-disk.*.disk_size_gb, count.index)}"
  }

  os_profile {
    computer_name  = "controlplane-${count.index}"
    admin_username = "${var.administrator_username}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.administrator_username}/.ssh/authorized_keys"
      key_data = "${var.administrator_ssh}"
    }
  }
}

resource "azurerm_virtual_machine" "etcd-machine" {
  count                            = "${var.rke_etcd_count}"
  name                             = "etcd-${count.index}"
  location                         = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name              = "${azurerm_resource_group.resourcegroup.name}"
  network_interface_ids            = ["${element(azurerm_network_interface.etcd_nic.*.id, count.index)}"]
  vm_size                          = "${var.etcd_node_vm_size}"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "etcd-os-disk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name            = "${element(azurerm_managed_disk.etcd-disk.*.name, count.index)}"
    managed_disk_id = "${element(azurerm_managed_disk.etcd-disk.*.id, count.index)}"
    create_option   = "Attach"
    lun             = 1
    disk_size_gb    = "${element(azurerm_managed_disk.etcd-disk.*.disk_size_gb, count.index)}"
  }

  os_profile {
    computer_name  = "etcd-${count.index}"
    admin_username = "${var.administrator_username}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.administrator_username}/.ssh/authorized_keys"
      key_data = "${var.administrator_ssh}"
    }
  }
}

# Create the network security group for the windows workers nodes
resource "azurerm_network_security_group" "nsg-windows-workers" {
  name                = "${azurerm_resource_group.resourcegroup.name}-nsg-windows-workers"
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

resource "azurerm_public_ip" "windows_worker_publicip" {
  count                        = "${var.windows_count}"
  name                         = "windows-worker-publicIp-${count.index}"
  location                     = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name          = "${azurerm_resource_group.resourcegroup.name}"
  allocation_method = "Dynamic"
}

resource "azurerm_network_interface" "windows_worker_nic" {
  count                     = "${var.windows_count}"
  name                      = "windows-worker-nic-${count.index}"
  location                  = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name       = "${azurerm_resource_group.resourcegroup.name}"
  network_security_group_id = "${azurerm_network_security_group.nsg-windows-workers.id}"

  ip_configuration {
    name                          = "windows-worker-ip-configuration-${count.index}"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    public_ip_address_id          = "${element(azurerm_public_ip.windows_worker_publicip.*.id, count.index)}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_managed_disk" "windows_worker-disk" {
  count                = "${var.windows_count}"
  name                 = "windows-worker-data-disk-${count.index}"
  location             = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name  = "${azurerm_resource_group.resourcegroup.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1023"
}

resource "azurerm_virtual_machine" "windows-machine" {
  count                            = "${var.windows_count}"
  name                             = "windows-${count.index}"
  location                         = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name              = "${azurerm_resource_group.resourcegroup.name}"
  network_interface_ids            = ["${element(azurerm_network_interface.windows_worker_nic.*.id, count.index)}"]
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
    name              = "windows-worker-os-disk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name            = "${element(azurerm_managed_disk.windows_worker-disk.*.name, count.index)}"
    managed_disk_id = "${element(azurerm_managed_disk.windows_worker-disk.*.id, count.index)}"
    create_option   = "Attach"
    lun             = 1
    disk_size_gb    = "${element(azurerm_managed_disk.windows_worker-disk.*.disk_size_gb, count.index)}"
  }

  os_profile {
    computer_name  = "windows-${count.index}"
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
      content      = "<AutoLogon><Password><Value>${var.administrator_password}</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>${var.administrator_username}</Username></AutoLogon>"
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
    user     = "${var.administrator_username}"
    password = "${var.administrator_password}"
  }
} 