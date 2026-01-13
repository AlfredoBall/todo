variable "hcp_organization" {
  description = "HashiCorp Cloud Platform Organization Name"
  type        = string
}

variable "hcp_email" {
  description = "HashiCorp Cloud Platform User Email"
  type        = string
}

variable "hcp_api_token" {
  description = "HashiCorp Cloud Platform API Token"
  type        = string
  sensitive   = true
}

variable "hcp_project_id" {
  description = "HashiCorp Cloud Platform Project ID"
  type        = string
}

variable "hcp_environments" {
  type = list(string)
}