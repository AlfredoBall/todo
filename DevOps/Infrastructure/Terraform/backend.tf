terraform {
  backend "remote" {
	organization = "amiasea"
	workspaces {
		name = "todo"
	}
  }
}