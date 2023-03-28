resource "azurerm_network_interface" "nic" {
  name                = "${var.deployment_prefix}dc-001-nic-001"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "Configuration"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "dc" {
  name                = "${var.deployment_prefix}dc-001"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2ms"
  admin_username      = "labadmin"
  admin_password      = "Azure12345678"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  boot_diagnostics {
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-core-smalldisk-g2"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "dcpromo" {
  name                 = "PromoteDomainController"
  virtual_machine_id   = azurerm_windows_virtual_machine.dc.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  settings = <<SETTINGS
  {
    "commandToExecute": "powershell -command \"Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools;$pwd=ConvertTo-SecureString -String 'Azure12345678' -Force -AsPlainText; Install-ADDSForest -DomainName 'corp.contoso.com' -InstallDNS -SafeModeAdministratorPassword $pwd -Confirm:$false\""
  }
  SETTINGS
}
#
resource "azurerm_backup_protected_vm" "dc001" {
  resource_group_name = azurerm_resource_group.rg.name
  recovery_vault_name = azurerm_recovery_services_vault.vault.name
  source_vm_id        = azurerm_windows_virtual_machine.dc.id
  backup_policy_id    = azurerm_backup_policy_vm.daily.id
}
