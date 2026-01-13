data "terraform_remote_state" "bootstrap" {
  backend = "local"

  config = {
    path = "../Bootstrap/terraform.tfstate"
  }
}