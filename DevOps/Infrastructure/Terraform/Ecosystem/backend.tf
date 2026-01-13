terraform {
  cloud {
    organization = var.hcp_organization
    workspaces {
      name    = "${var.hcp_project}-ecosystem"
      project = var.hcp_project
    }
  }
}