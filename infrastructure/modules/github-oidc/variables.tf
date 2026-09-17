variable "github_organization" {
  description = "GitHub organization or username that owns the repository."
  type        = string
}

variable "github_repository" {
  description = "GitHub repository authorized to assume the deployment role."
  type        = string
}

variable "github_branch" {
  description = "GitHub branch authorized to assume the deployment role."
  type        = string
  default     = "main"
}

variable "role_name" {
  description = "Name of the IAM role assumed by GitHub Actions."
  type        = string
}

variable "site_bucket_name" {
  description = "S3 bucket containing the portfolio frontend."
  type        = string
}

variable "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution used by the portfolio."
  type        = string
}