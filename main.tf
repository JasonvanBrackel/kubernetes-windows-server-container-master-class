# Configure the Rancher2 provider
provider "rancher2" {
  api_url    = "${var.rancher_api_url}"
  token_key  = "${var.rancher_api_token}"
}

# Create a new rke Cluster 
resource "rancher2_cluster" "windows-demo" {
  name = "windows-demo-cluster-test"
  description = "Custom Windows Cluster for the Rancher Master Class"
  kind = "rke"
  rke_config {
    network {
      plugin = "flannel"
    }
    cloud_provider {
      azure_cloud_provider {
        aad_client_id = "${lookup(var.azure_service_principal, "client_id")}"
        aad_client_secret = "${lookup(var.azure_service_principal, "client_secret")}"
        subscription_id = "${lookup(var.azure_service_principal, "subscription_id")}"
        tenant_id = "${lookup(var.azure_service_principal, "tenant_id")}"
      }
    }
  }
}

# Create the Node Templates
# Create the Linux Node Template
resource "rancher2_node_template" "linux-template" {
  name = "ubuntu-node-template"
  description = "Ubuntu Linux Node Template East US"
  engine_install_url = "https://releases.rancher.com/install-docker/18.09.2.sh"

  azure_config {
    client_id = "${lookup(var.azure_service_principal, "client_id")}"
    client_secret = "${lookup(var.azure_service_principal, "client_secret")}"
    subscription_id = "${lookup(var.azure_service_principal, "subscription_id")}"
    availability_set = "rancher-linux-nodes"
    environment = "AzurePublicCloud"
    image = "canonical:UbuntuServer:16.04.0-LTS:latest"
    location = "${var.azure_region}"
    docker_port = "2376"
    open_port = ["6443/tcp","2379/tcp","2380/tcp","8472/udp","4789/udp","10256/tcp","10250/tcp","10251/tcp","10252/tcp"]
    resource_group = "${var.azure_resource_group}"
    ssh_user = "${var.administrator_username}"
    subnet = "${azurerm_subnet.subnet.name}"
    vnet = "${azurerm_virtual_network.network.name}"
    storage_type = "Standard_LRS"
    size = "${var.linux_node_vm_size}"
  }
}

# Create node pools for the rke Cluster
# Create a control plane pool
resource "rancher2_node_pool" "linux-pool" {
  cluster_id =  "${rancher2_cluster.windows-demo.id}"
  name = "control-plane"
  hostname_prefix =  "control-plane-"
  node_template_id = "${rancher2_node_template.linux-template.id}"
  quantity = "${var.control_plane_count}"
  control_plane = true
  etcd = true
  worker = true
}

# Windows Node Templates are not yet supported, this will attempt to provision the nodes, but fail due lack of an ssh c
# Create the Windows Node Template
# resource "rancher2_node_template" "windows-template" {
#   name = "windows1803-eastus-Standard_DS2_v2"
#   description = "Windows Server 1803 Node Template East US"
#   engine_install_url = ""

#   azure_config {
#     client_id = "${lookup(var.azure_service_principal, "client_id")}"
#     client_secret = "${lookup(var.azure_service_principal, "client_secret")}"
#     subscription_id = "${lookup(var.azure_service_principal, "subscription_id")}"
#     availability_set = "docker-machine-windows"
#     environment = "AzurePublicCloud"
#     image = "MicrosoftWindowsServer:WindowsServerSemiAnnual:Datacenter-Core-1803-with-Containers-smalldisk:latest"
#     location = "eastus"
#     docker_port = "2376"
#     open_port = ["6443/tcp","2379/tcp","2380/tcp","8472/udp","4789/udp","10256/tcp","10250/tcp","10251/tcp","10252/tcp","5985/tcp","5986/tcp"]
#     resource_group = "docker-machine"
#     ssh_user = "docker-user"
#     subnet = "docker-machine"
#     vnet = "docker-machine-vnet"
#     storage_type = "Standard_LRS"
#     size = "Standard_D2_v2"
#   }
# }

# resource "rancher2_node_pool" "windows-pool" {
#   cluster_id =  "${rancher2_cluster.windows-demo.id}"
#   name = "windows-workers"
#   hostname_prefix =  "windows-worker-"
#   node_template_id = "${rancher2_node_template.windows-template.id}"
#   quantity = "${var.windows_count}"
#   control_plane = false
#   etcd = false
#   worker = false
# }