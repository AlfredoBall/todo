resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group_name}-${var.target_env}"
  location = var.location
  tags     = var.resource_tags
}

resource "azurerm_service_plan" "service_plan_linux" {
  name                = "${var.service_plan_linux_name}-${var.target_env}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "F1"

  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_service_plan" "service_plan_windows" {
  name                = "${var.service_plan_windows_name}-${var.target_env}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Windows"
  sku_name            = "B1"

  depends_on = [azurerm_resource_group.rg]
}

