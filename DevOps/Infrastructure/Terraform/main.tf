resource "azurerm_service_plan" "service_plan" {
  name                = var.service_plan_name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = "F1"
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.resource_tags
}

module "api" {
  source                    = "./api"
  api_app_service_name      = var.api_app_service_name
  api_app_registration_name = var.api_app_registration_name
  sign_in_audience          = var.sign_in_audience
  tenant_id                 = var.tenant_id
  location                  = var.location
  resource_group_name       = var.resource_group_name
  service_plan_id           = azurerm_service_plan.service_plan.id
  frontend_default_hostname = module.frontend.frontend_default_hostname
}

module "frontend" {
  source                         = "./frontend"
  frontend_app_service_name      = var.frontend_app_service_name
  sign_in_audience               = var.sign_in_audience
  tenant_id                      = var.tenant_id
  location                       = var.location
  resource_group_name            = var.resource_group_name
  service_plan_id                = azurerm_service_plan.service_plan.id
  api_app_registration_client_id = module.api.api_app_registration_client_id
  api_scope_string               = module.api.api_scope_string
  api_scope_uuid                 = module.api.api_scope_uuid
  api_service_principal_id       = module.api.api_service_principal_id
}
