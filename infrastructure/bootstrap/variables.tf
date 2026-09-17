variable "aws_region" {
  description = "AWS Region used for the Terraform state infrastructure."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", var.aws_region))
    error_message = "The AWS region must use a valid format such as us-east-1."
  }
}

variable "project_name" {
  description = "Project identifier used for naming and tagging."
  type        = string
  default     = "secure-cloud-portfolio"

  validation {
    condition = (
      length(var.project_name) >= 3 &&
      length(var.project_name) <= 30 &&
      can(regex("^[a-z0-9-]+$", var.project_name))
    )

    error_message = "The project name must contain 3-30 lowercase letters, numbers, or hyphens."
  }
}

variable "owner" {
  description = "Owner identifier applied to supported AWS resources."
  type        = string
  default     = "kellan-wilkerson"
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name used for Terraform state."
  type        = string

  validation {
    condition = (
      length(var.state_bucket_name) >= 3 &&
      length(var.state_bucket_name) <= 63 &&
      can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.state_bucket_name))
    )

    error_message = "The state bucket name must be a valid, globally unique S3 bucket name."
  }
}