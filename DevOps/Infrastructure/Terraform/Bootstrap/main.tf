resource "tfe_organization" "organization" {
  name  = var.hcp_organization
  email = var.hcp_email
}

resource "tfe_project" "project" {
  name         = var.project_name
  organization = tfe_organization.organization.name
}

resource "tfe_workspace" "ecosystem" {
  name           = "${var.project_name}-ecosystem"
  organization   = tfe_organization.organization.name
  project_id     = tfe_project.project.id
  queue_all_runs = false
}