variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "github_org" {
  description = "GitHub Organization"
  type        = string
}

variable "github_repo" {
  description = "GitHub Repository Name"
  type        = string
}

variable "branches" {
  description = "GitHub Repository Branches"
  type        = list(string)
}

variable "environments" {
  description = "Environments"
  type        = list(string)
}