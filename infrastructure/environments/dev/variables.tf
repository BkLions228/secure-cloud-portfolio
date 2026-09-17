variable "aws_region" {
  description = "AWS Region used for development resources."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project identifier used for naming and tagging."
  type        = string
  default     = "secure-cloud-portfolio"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"

  validation {
    condition = contains(
      ["dev", "test", "stage", "prod"],
      var.environment
    )

    error_message = "Environment must be dev, test, stage, or prod."
  }
}

variable "owner" {
  description = "Owner identifier applied to supported AWS resources."
  type        = string
  default     = "kellan-wilkerson"
}

variable "site_bucket_name" {
  description = "Globally unique name for the private portfolio S3 bucket."
  type        = string

  validation {
    condition = (
      length(var.site_bucket_name) >= 3 &&
      length(var.site_bucket_name) <= 63 &&
      can(regex(
        "^[a-z0-9][a-z0-9.-]*[a-z0-9]$",
        var.site_bucket_name
      ))
    )

    error_message = "The site bucket name must be a valid S3 bucket name."
  }
}

variable "price_class" {
  description = "CloudFront price class."
  type        = string
  default     = "PriceClass_100"

  validation {
    condition = contains(
      ["PriceClass_100", "PriceClass_200", "PriceClass_All"],
      var.price_class
    )

    error_message = "CloudFront price class must be PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}

variable "enable_versioning" {
  description = "Whether S3 object versioning is enabled."
  type        = bool
  default     = true
}