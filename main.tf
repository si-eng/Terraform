terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.38.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  # Fill according to your azure protal.
  subscription_id = ""
  tenant_id = ""
  client_id = ""
  client_secret = ""
  features {
    
  }
}

resource "azurerm_resource_group" "sakshirg2" {
  name     = "sakshirg2"
  location = "westeurope"
}

resource "azurerm_network_security_group" "sakshirg2" {
  name                = "acceptanceTestSecurityGroup1"
  location            = azurerm_resource_group.sakshirg2.location
  resource_group_name = azurerm_resource_group.sakshirg2.name

  security_rule {
    access = "Allow"
    destination_address_prefix = "*"
    destination_port_range = "80"
    direction = "Inbound"
    name = "Http"
    priority = 100
    protocol = "Tcp"
    source_address_prefix = "*"
    source_port_range = "*"
  }
  security_rule {
    access = "Allow"
    destination_address_prefix = "*"
    destination_port_range = "22"
    direction = "Inbound"
    name = "ssh"
    priority = 101
    protocol = "Tcp"
    source_address_prefix = "*"
    source_port_range = "*"
  }
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "sakshirg2" {
  name                = "vnetsak"
  resource_group_name = azurerm_resource_group.sakshirg2.name
  location            = azurerm_resource_group.sakshirg2.location
  address_space       = ["10.0.0.0/16"]
}
# Create our Subnet to hold our VM - Virtual Machines
resource "azurerm_subnet" "sakshirg2" {
  name                 = "saksubnet"
  resource_group_name  = azurerm_resource_group.sakshirg2.name
  virtual_network_name = azurerm_virtual_network.sakshirg2.name
  address_prefixes       = ["10.0.1.0/24"]
}
resource "azurerm_subnet_network_security_group_association" "association" {
    subnet_id = azurerm_subnet.sakshirg2.id
    network_security_group_id = azurerm_network_security_group.sakshirg2.id
}
# Create our Azure Storage Account
resource "azurerm_storage_account" "newstorage-new" {
  name                     = "sakshiaccountterraform"
  resource_group_name      = azurerm_resource_group.sakshirg2.name
  location                 = azurerm_resource_group.sakshirg2.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
resource "azurerm_public_ip" "idaddress" {
  name = "sakshiterra-ip"
  location = azurerm_resource_group.sakshirg2.location
  resource_group_name = azurerm_resource_group.sakshirg2.name
  allocation_method = "Dynamic"
}
# Create our vNIC for our VM and assign it to our Virtual Machines Subnet
resource "azurerm_network_interface" "vmnic" {
  name                = "sakshivnic"
  location            = azurerm_resource_group.sakshirg2.location
  resource_group_name = azurerm_resource_group.sakshirg2.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sakshirg2.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.idaddress.id
  }
}
# Create our Virtual Machine -
resource "azurerm_virtual_machine" "sakshivm_new" {
  name                  = "sakshisvm"
  location              = azurerm_resource_group.sakshirg2.location
  resource_group_name   = azurerm_resource_group.sakshirg2.name
  network_interface_ids = [azurerm_network_interface.vmnic.id]
  vm_size               = "Standard_B1s"
  delete_os_disk_on_termination = true
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "sakshivm01os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name      = "sakshivm"
    admin_username     = "adminuser"
    admin_password     = "sakshi@123"
    custom_data = file("datafile.sh")
  }
  os_profile_linux_config  {
    disable_password_authentication = true
    ssh_keys {
      key_data = file("C:\\Users\\sharmasakshi\\.ssh\\key1.pub")
      path = "/home/adminuser/.ssh/authorized_keys"
    }
  }
}
