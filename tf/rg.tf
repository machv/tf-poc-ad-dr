resource "azurerm_resource_group" "rg" {
  name     = "${var.deployment_prefix}rg"
  location = "westeurope"
}
