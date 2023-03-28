locals {
  isolation_count = 1 # how many separate environments should be deployed
}

resource "azurerm_storage_account" "sa_restore" {
  name                      = "pocdhladdrrestores"
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = azurerm_resource_group.rg.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  account_kind              = "StorageV2"
  access_tier               = "Hot"
  enable_https_traffic_only = true
  min_tls_version           = "TLS1_2"
}

resource "azurerm_resource_group" "isolated_rg" {
  count = local.isolation_count

  name     = "${var.deployment_prefix}rg-isolated-${format("%03s", count.index + 1)}"
  location = "westeurope"
}

resource "azurerm_virtual_network" "isolated_vnet" {
  count = local.isolation_count

  name                = "${var.deployment_prefix}vnet-isolated-${format("%03s", count.index + 1)}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.isolated_rg[count.index].location
  resource_group_name = azurerm_resource_group.isolated_rg[count.index].name
}

resource "azurerm_subnet" "isolated_subnet" {
  count = local.isolation_count

  name                 = "internal"
  resource_group_name  = azurerm_resource_group.isolated_rg[count.index].name
  virtual_network_name = azurerm_virtual_network.isolated_vnet[count.index].name
  address_prefixes     = ["10.0.2.0/24"]
}
