provider "azurerm" {
  features {}
}

variable "password" {
  description = "The password for the VM to login over ssh"
}

resource "azurerm_resource_group" "main" {
  name     = "wsb-resources"
  location = "eastus"
}

resource "azurerm_virtual_network" "main" {
  name                = "wsb-network"
  address_space       = ["10.0.0.0/22"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "public_ip" {
  name                = "wsb-public-ip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "main" {
  name                = "wsb-nic"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"

    public_ip_address_id = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name                            = "wsb-vm"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = "Standard_B1s"
  admin_username                  = "ubuntu"
  admin_password                  = var.password
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
  
  tags = {
  environment = "test"
  }
}

data "azurerm_public_ip" "example" {
  name                = azurerm_public_ip.example.name
  resource_group_name = azurerm_windows_virtual_machine.example.resource_group_name
  depends_on          = [azurerm_windows_virtual_machine.example]
}

output "public_ip_address" {
  value = data.azurerm_public_ip.example.ip_address
}
