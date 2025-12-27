terraform {
  cloud {
	organization = "amiasea"
	workspaces {
	  project = "todo"
	  tags = ["environment"]
	}
  }
}