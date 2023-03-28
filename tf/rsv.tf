resource "azurerm_recovery_services_vault" "vault" {
  name                = "${var.deployment_prefix}rsv"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  soft_delete_enabled = false
  storage_mode_type   = "LocallyRedundant"
}

resource "azurerm_backup_policy_vm" "daily" {
  name                = "dc-recovery-vault-policy"
  resource_group_name = azurerm_resource_group.rg.name
  recovery_vault_name = azurerm_recovery_services_vault.vault.name
  policy_type         = "V2"
  timezone            = "UTC"

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 10
  }

  retention_weekly {
    count    = 42
    weekdays = ["Wednesday", "Friday", "Saturday"]
  }

  retention_monthly {
    count    = 6
    weekdays = ["Sunday", "Wednesday"]
    weeks    = ["First", "Last"]
  }
}
