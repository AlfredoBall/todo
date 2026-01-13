variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
  sensitive   = true
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "hcp_organization" {
  description = "HashiCorp Cloud Platform Organization Name"
  type        = string
}

variable "hcp_project" {
  description = "HashiCorp Cloud Platform Project Name"
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

variable "github_organization" {
    description = "GitHub Organization"
    type       = string
}

variable "github_repository" {
    description = "GitHub Repository Name"
    type       = string
}

variable "branches" {
  type = list(string)
}

variable "environments" {
  type = list(string)
}

variable "location" {
  description = "Azure location for resources"
  type        = string
  default     = "centralus"
}