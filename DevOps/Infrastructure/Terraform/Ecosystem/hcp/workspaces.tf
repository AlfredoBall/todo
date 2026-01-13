resource "tfe_organization" "organization" {
  name  = var.hcp_organization
  email = var.hcp_email
}

resource "tfe_workspace" "workspaces" {
    for_each = toset(var.hcp_environments)

    project_id = var.hcp_project_id
    name                 = "todo-${each.key}"
    organization         = tfe_organization.organization.name
    queue_all_runs       = false
}

resource "tfe_workspace_settings" "workspace_settings" {
  for_each = toset(var.hcp_environments)

  workspace_id   = tfe_workspace.workspaces[each.key].id
  execution_mode = "local"
  tags = { "environment" = "" }
}

