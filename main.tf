resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = random_pet.rg_name.id
}

# redes

resource "azurerm_network_security_group" "nsg1" {
  name                = "NSG01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

    security_rule {
    name                       = "PermitirTodo"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

resource "azurerm_virtual_network" "vnet1" {
  name                = "redvirtual01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "test"
  }
}

resource "azurerm_subnet" "subnet1" { 
    name             = "subnet1"
    virtual_network_name = azurerm_virtual_network.vnet1.name
    resource_group_name = azurerm_resource_group.rg.name
    address_prefixes = ["10.0.1.0/24"]
    
  }

# asignacion del NSG

resource "azurerm_subnet_network_security_group_association" "asignacionNSG" {
  subnet_id = azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
}


# ip publica

# resource "azurerm_public_ip" "publicip" {
#   name                = "IpPublica"
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = azurerm_resource_group.rg.location
#   allocation_method   = "Static"

#   tags = {
#     environment = "labo"
#   }
# }

#placa de red 

resource "azurerm_network_interface" "placared" {
  count = 4
  name                = "placa-nic${count.index + 1}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipplacared"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    #public_ip_address_id = azurerm_public_ip.publicip.id
  }
}

#maquina virtual 

resource "azurerm_virtual_machine" "vmazure" {
  count = 4
  name                  = "VM-${count.index+1}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.placared [count.index].id]
  vm_size               = "Standard_DS1_v2"
  

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  storage_os_disk {
    name              = "nodo1disk${count.index+1}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "VM${count.index+1}"
    admin_username = "levisman"
    admin_password = "Otro4dejulio"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "labo"
  }
}