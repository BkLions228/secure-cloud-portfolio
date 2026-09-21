variable "github_oidc_provider_arn" {
  description = "ARN of the existing GitHub Actions OIDC provider."
  type        = string
}

variable "github_organization" {
  description = "GitHub organization or username that owns the repository."
  type        = string
}

variable "github_organization_id" {
  description = "Immutable GitHub numeric ID for the organization or user."
  type        = string
}

variable "github_repository" {
  description = "GitHub repository authorized to assume the backend deployment role."
  type        = string
}

variable "github_repository_id" {
  description = "Immutable GitHub numeric ID for the repository."
  type        = string
}

variable "github_branch" {
  description = "GitHub branch authorized to assume the backend deployment role."
  type        = string
  default     = "main"
}

variable "role_name" {
  description = "Name of the GitHub Actions backend deployment IAM role."
  type        = string
}

variable "project_name" {
  description = "Project name used to scope backend deployment resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}
