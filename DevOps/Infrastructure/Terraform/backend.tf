terraform {
  backend "remote" {
	organization = "amiasea"
	workspaces {
		name = "todo"
	}
	execution_mode = "local"
  }
}