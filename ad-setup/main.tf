# ##########################################################
# ## Create DC VM & AD Forest
# ##########################################################
# terraform {
#   required_providers {
#     azurerm = {
#       source  = "hashicorp/azurerm"
#       version = "~>2.0"
#     }
#   }
# }

# # Configure the Microsoft Azure Provider
# provider "azurerm" {
#   features {}
# }

# # Create a resource group
# resource "azurerm_resource_group" "rg_name" {
#   name     = "avd-ad-rg"
#   location = "West Europe"
# }

# # Create a virtual network within the resource group
# resource "azurerm_virtual_network" "ad_vnet" {
#   name                = "avd-ad-vnet"
#   resource_group_name = azurerm_resource_group.rg_name.name
#   location            = azurerm_resource_group.rg_name.location
#   address_space       = ["10.200.0.0/16"]
#   #  subnet {
#   #   name           = "subnet1"
#   #   address_prefix = "10.200.1.0/27"
#   # }

# }

# resource "azurerm_subnet" "ad_subnet" {
#   name                 = "internal"
#   resource_group_name  = azurerm_resource_group.rg_name.name
#   virtual_network_name = azurerm_resource_group.rg_name.location
#   address_prefixes     = ["10.200.1.0/24"]
# }

# resource "azurerm_network_interface" "ad_nic" {
#   name                = "ad-nic"
#   location            = azurerm_resource_group.rg_name.location
#   resource_group_name = azurerm_resource_group.rg_name.name

#   ip_configuration {
#     name                          = "internal"
#     subnet_id                     = azurerm_subnet.ad_subnet.id
#     private_ip_address_allocation = "Dynamic"
#   }
# }

# module "active-directory" {
#   source                        = "./modules/active-directory"
#   resource_group_name           = azurerm_resource_group.rg_name.name
#   location                      = azurerm_resource_group.rg_name.location
#   prefix                        = "avd-test"
#   subnet_id                     = azurerm_subnet.ad_subnet.id
#   active_directory_domain       = "${var.prefix}.local"
#   active_directory_netbios_name = "${var.prefix}"
#   private_ip_address            = "10.200.1.4"
#   admin_username                = "faizal"
#   admin_password                = "avdtest123456"
# }


provider "azurerm" {
  features {}
}

locals {
  virtual_machine_name = "${var.prefix}-dc1"
  virtual_machine_fqdn = "${local.virtual_machine_name}.${var.active_directory_domain}"
  custom_data_params   = "Param($RemoteHostName = \"${local.virtual_machine_fqdn}\", $ComputerName = \"${local.virtual_machine_name}\")"
  custom_data_content  = "${local.custom_data_params} ${file("files/winrm.ps1")}"

  import_command       = "Import-Module ADDSDeployment"
  password_command     = "$password = ConvertTo-SecureString ${var.admin_password} -AsPlainText -Force"
  install_ad_command   = "Add-WindowsFeature -name ad-domain-services -IncludeManagementTools"
  configure_ad_command = "Install-ADDSForest -CreateDnsDelegation:$false -DomainMode Win2012R2 -DomainName ${var.active_directory_domain} -DomainNetbiosName ${var.active_directory_netbios_name} -ForestMode Win2012R2 -InstallDns:$true -SafeModeAdministratorPassword $password -Force:$true"
  shutdown_command     = "shutdown -r -t 10"
  exit_code_hack       = "exit 0"
  powershell_command   = "${local.import_command}; ${local.password_command}; ${local.install_ad_command}; ${local.configure_ad_command}; ${local.shutdown_command}; ${local.exit_code_hack}"
}

resource "azurerm_resource_group" "rg_name" {
  name     = "avd-ad-resources"
  location = "West Europe"
}

resource "azurerm_virtual_network" "avd_ad_vnet" {
  name                = "avd-ad-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg_name.location
  resource_group_name = azurerm_resource_group.rg_name.name
}

resource "azurerm_subnet" "avd_ad_subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.rg_name.name
  virtual_network_name = azurerm_virtual_network.avd_ad_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "ad_bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg_name.name
  virtual_network_name = azurerm_virtual_network.avd_ad_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "ad_bastion_ip" {
  name                = "bastion_pip"
  location            = azurerm_resource_group.rg_name.location
  resource_group_name = azurerm_resource_group.rg_name.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "ad_bastion_host" {
  name                = "adbastion"
  location            = azurerm_resource_group.rg_name.location
  resource_group_name = azurerm_resource_group.rg_name.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.ad_bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.ad_bastion_ip.id
  }
}
resource "azurerm_network_interface" "avd_ad_nic" {
  name                = "avd-ad-nic"
  location            = azurerm_resource_group.rg_name.location
  resource_group_name = azurerm_resource_group.rg_name.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.avd_ad_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "domain_controller" {
  name                          = "${local.virtual_machine_name}"
  location                      = azurerm_resource_group.rg_name.location
  resource_group_name           = azurerm_resource_group.rg_name.name
  network_interface_ids = [
    azurerm_network_interface.avd_ad_nic.id,
  ]
  #network_interface_ids         = azurerm_network_interface.example.id
  vm_size                       = "Standard_D2s_v3"
  delete_os_disk_on_termination = false

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${local.virtual_machine_name}-disk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${local.virtual_machine_name}"
    admin_username = "${var.admin_username}"
    admin_password = "${var.admin_password}"
    custom_data    = "${local.custom_data_content}"
  }

  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = false

    additional_unattend_config {
      pass         = "oobeSystem"
      component    = "Microsoft-Windows-Shell-Setup"
      setting_name = "AutoLogon"
      content      = "<AutoLogon><Password><Value>${var.admin_password}</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>${var.admin_username}</Username></AutoLogon>"
    }

    # Unattend config is to enable basic auth in WinRM, required for the provisioner stage.
    additional_unattend_config {
      pass         = "oobeSystem"
      component    = "Microsoft-Windows-Shell-Setup"
      setting_name = "FirstLogonCommands"
      content      = "${file("files/FirstLogonCommands.xml")}"
    }
  }
}

resource "azurerm_virtual_machine_extension" "create-active-directory-forest" {
  name                 = "create-active-directory-forest"
  # location             = azurerm_resource_group.rg_name.location
  # resource_group_name  = azurerm_resource_group.rg_name.name
  # virtual_machine_name = azurerm_virtual_machine.domain_controller.name
  virtual_machine_id = azurerm_virtual_machine.domain_controller.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe -Command \"${local.powershell_command}\""
    }
SETTINGS
}
