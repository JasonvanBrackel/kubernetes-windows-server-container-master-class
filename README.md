# Windows Server Master Class Demo Environment

This module can be used to standup a Kubernetes Cluster on Azure IaaS (not AKS), with Windows Server Container Nodes.

## Warning

This module is a working in progress.  As of the time of this presentation the Rancher support for Windows Server Containers is experimental and only supports Windows Server 1803 with Flannel CNI on host-gw mode for the Windows Nodes.  The Linux nodes will run Flannel CNI on vxlan mode.

In addtion at the time of this presentation the most recently version of Kubernetes is 1.13 and the Windows Server Container support is in beta.  It should be GA by 1.14 per sig-windows

This is not a production-ready setup.  It's setup so that the remote-exec provisioner can use an insecure method for executing WinRM commands. This should be cleaned up after provisioning so that that the machine is secure after provisioning.

WinRM is flaky at best from Linux and MacOS so Windows is recommended.

### Building the Terraform Provider for Rancher 2 in Windows

The make file will not build in Windows.  This was how I got a working terraform provider.  

I already had golang 11 installed via chocolatey.

```powershell
go get -u github.com/rancher/terraform-provider-rancher2/rancher2
go build github.com/rancher/terraform-provider-rancher2
cp $env:GOPATH\src\github.com\rancher\terraform-provider-rancher2\terraform-provider-rancher2.exe .\.terraform\plugins\windows_amd64\
```

## Prerequisites

### Terraform installed

You can get Terraform for your OS [here](https://www.terraform.io/downloads.html).  As of the time of the presentation Terraform is 0.11.11

### Rancher Terraform Provider for Rancher 2.x

As of the time of this presentation the Rancher 2.x module for Terraform is still going through the approval process.  Instructions for building and installing the Terraform provider is [here](https://github.com/rancher/terraform-provider-rancher2/#building-the-provider)

### Azure AD Service Principal

This Terraform module requires the use of an Azure Active Directory (Azure AD) Service Principal.  The configuation of this is outside of the scope of this document, but you can find more information on the document [Service Principals with Azure Kubernetes Service (AKS)](https://docs.microsoft.com/en-us/azure/aks/kubernetes-service-principal).

## Configuration

All of the variables for this module are set via terraform in the terraform.tfvars file.  An example file [terraform.tfvars.example](terraform.tfvars.example) has been provided as reference.

## Running

```bash
terraform init
terraform plan
terraform apply
```

### What's ths doing some items are done serially, some in parallel

- Terraform Uses the Azure Provider to
  - Create a resource group
  - Create a virtual network
  - Create a subnet
  - Create a network security group
  - Create the windows workers
    - Create the nic and public ip for the workers
    - Create os and storage disks
    - Once the VM is up it registers with cluster via a published command from the Rancher 2.x Terraform Provider
- Terraform Uses the Rancher 2.x Provider to
  - Create the linux node template
  - Create the linux cluster using the Azure IaaS path and associated node pools