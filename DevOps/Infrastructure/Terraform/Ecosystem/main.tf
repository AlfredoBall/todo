module "hcp" {
    source = "./hcp"
    hcp_project_id = data.terraform_remote_state.bootstrap.outputs.project_id
    hcp_environments = var.environments
    hcp_email = var.hcp_email
    hcp_organization = var.hcp_organization
    hcp_api_token = var.hcp_api_token
}