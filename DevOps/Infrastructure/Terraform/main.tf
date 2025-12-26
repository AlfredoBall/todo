resource "azurerm_service_plan" "service_plan_linux" {
  name                = "${ var.service_plan_linux_name }-${ var.target_env }"
  location            = var.location
  resource_group_name = "${ var.resource_group_name }-${ var.target_env }"
  os_type             = "Linux"
  sku_name            = "F1"
}

resource "azurerm_service_plan" "service_plan_windows" {
  name                = var.service_plan_windows_name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Windows"
  sku_name            = "B1"
}

resource "azurerm_resource_group" "rg" {
  name     = "${ var.resource_group_name }-${ var.target_env }"
  location = var.location
  tags     = var.resource_tags
}

module "api" {
  source                    = "./api"
  api_app_service_name      = "${ var.api_app_service_name }-${ var.target_env }"
  api_app_registration_name = "${ var.api_app_registration_name }-${ var.target_env }"
  sign_in_audience          = var.sign_in_audience
  location                  = var.location
  resource_group_name       = "${ var.resource_group_name }-${ var.target_env }"
  service_plan_id           = azurerm_service_plan.service_plan_windows.id
  frontend_default_hostname = module.frontend.frontend_default_hostname
  api_build_configuration   = var.api_build_configuration
  visual_studio_version     = var.visual_studio_version
  target_env                = var.target_env
}

module "frontend" {
  source                         = "./frontend"
  frontend_app_service_name      = "${ var.frontend_app_service_name }-${ lower(var.target_env) }"
  sign_in_audience               = var.sign_in_audience
  location                       = var.location
  resource_group_name            = "${ var.resource_group_name }-${ lower(var.target_env) }"
  service_plan_id                = azurerm_service_plan.service_plan_linux.id
  api_app_registration_client_id = module.api.api_app_registration_client_id
  api_scope_uri                  = module.api.api_scope_uri
  api_scope_uuid                 = module.api.api_scope_uuid
  api_service_principal_id       = module.api.api_service_principal_id
}

data "azuread_client_config" "current" {}
