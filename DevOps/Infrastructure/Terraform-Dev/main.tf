module "api" {
  source           = "./api"
  sign_in_audience = var.sign_in_audience
}

module "frontend" {
  source                                = "./frontend"
  sign_in_audience                      = var.sign_in_audience
  api_app_registration_client_id        = module.api.app_registration_client_id
  api_app_registration_service_principal_id = module.api.app_registration_service_principal_id
  react_redirect_uri                    = var.react_redirect_uri
  angular_redirect_uri                  = var.angular_redirect_uri

}

data "azuread_client_config" "current" {}

