resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.resource_tags
}

resource "azurerm_service_plan" "service_plan_windows" {
  name                = "${var.service_plan_windows_name}-${var.target_env}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Windows"
  sku_name            = "B1"

  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_container_app_environment" "frontend_environment" {
  name                       = "Environment-${title(var.target_env)}"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.rg.name

  depends_on = [azurerm_resource_group.rg]
}

module "api" {
  source                    = "./api"
  api_app_service_name      = "${var.api_app_service_name}-${var.target_env}"
  api_app_registration_name = "${var.api_app_registration_name}-${var.target_env}"
  sign_in_audience          = var.sign_in_audience
  location                  = var.location
  resource_group_name       = azurerm_resource_group.rg.name
  service_plan_id           = azurerm_service_plan.service_plan_windows.id
  api_build_configuration   = var.api_build_configuration
  visual_studio_version     = var.visual_studio_version
  target_env                = var.target_env
}

module "frontend" {
  source                         = "./frontend"
  frontend_environment_id        = azurerm_container_app_environment.frontend_environment.id
  frontend_container_app_name    = "${var.frontend_container_app_name}-${var.target_env}"
  frontend_container_name        = "${var.frontend_container_name}-${var.target_env}"
  sign_in_audience               = var.sign_in_audience
  location                       = var.location
  resource_group_name            = var.resource_group_name
  api_app_registration_client_id = module.api.api_app_registration_client_id
  api_scope_uri                  = module.api.api_scope_uri
  api_scope_uuid                 = module.api.api_scope_uuid
  api_service_principal_id       = module.api.api_service_principal_id
  target_env                     = var.target_env
  dockerhub_username             = var.dockerhub_username
  frontend_image                 = var.frontend_image
  dockerhub_password             = var.dockerhub_password
}
