provider "azurerm" {
 version = ">=2.30"
 features {}
  subscription_id = "6f8c51c8-7fed-4dc6-b1d7-651a5cdcf7b5"
}
    


# Resource Group

resource "azurerm_resource_group" "testrg" {
    name = var.resource_group
    location = var.location

    tags = {
    environment = var.environment
  }
  
}

# virtual network

resource "azurerm_virtual_network" "testvnet" {
  name = var.vnet_name
  address_space = [var.address_space]
  resource_group_name = azurerm_resource_group.testrg.name
  location = azurerm_resource_group.testrg.location

  tags = {
    environment = var.environment
  }

}

# subnet 

resource "azurerm_subnet" "subnet" {
    name                   = var.subnet_name[count.index]
    resource_group_name    = azurerm_resource_group.testrg.name
    virtual_network_name   = azurerm_virtual_network.testvnet.name
    address_prefixes       = [var.subnet_prefixes[count.index]]
    count                  = length(var.subnet_name)
}

# public ip
resource "azurerm_public_ip" "pubip" {
    name = "pubip"
    location = var.location
    resource_group_name = var.resource_group
    allocation_method = "Dynamic"
    idle_timeout_in_minutes = 10
    sku = "basic"
}

# nic 
resource "azurerm_network_interface" "vm" {
  name                = var.network_interface_name
  location            = var.location
  resource_group_name = var.resource_group

  ip_configuration {
    name                          = "myNicConfiguration"
    subnet_id                     = azurerm_subnet.subnet[0].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.pubip.id

  
   
  }
}

# vm creation

resource "azurerm_windows_virtual_machine" "vm" {
  name                  = var.windows_vm_name
  location              = var.location
  resource_group_name   = var.resource_group
  network_interface_ids = [azurerm_network_interface.vm.id]
  size                  = "Standard_DS1_v2"
  admin_username        = var.adminusername
  admin_password        = azurerm_key_vault_secret.vmpassword.value

  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "20h1-pro-g2"
    version   = "latest"
  }
}

  #Create KeyVault ID
resource "random_id" "kvname" {
  byte_length = 5
  prefix = "keyvault"
}
#Keyvault Creation
data "azurerm_client_config" "current" {}
resource "azurerm_key_vault" "kv1" {
  depends_on                  = [azurerm_resource_group.testrg]
  name                        = random_id.kvname.hex
  location                    = var.location
  resource_group_name         = var.resource_group
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name = "standard"
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    key_permissions = [
      "get",
    ]
    secret_permissions = [
      "get", "backup", "delete", "list", "purge", "recover", "restore", "set",
    ]
    storage_permissions = [
      "get",
    ]

  }
}

#Create KeyVault VM password
resource "random_password" "vmpassword" {
  length = 20
  special = true
}
#Create Key Vault Secret
resource "azurerm_key_vault_secret" "vmpassword" {
  name         = "vmpassword"
  value        = random_password.vmpassword.result
  key_vault_id = azurerm_key_vault.kv1.id
  depends_on = [ azurerm_key_vault.kv1 ]
}

resource "azurerm_storage_account" "storage_1" {
  name                     = var.storage_1
  resource_group_name      = azurerm_resource_group.testrg.name
  location                 = azurerm_resource_group.testrg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = var.environment
  }

}