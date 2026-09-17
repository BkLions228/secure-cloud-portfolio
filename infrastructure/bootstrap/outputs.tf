output "state_bucket_name" {
  description = "Name of the S3 bucket used for Terraform remote state."
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "ARN of the S3 bucket used for Terraform remote state."
  value       = aws_s3_bucket.terraform_state.arn
}

output "aws_region" {
  description = "AWS Region containing the state bucket."
  value       = var.aws_region
}

output "development_state_key" {
  description = "Recommended S3 key for development Terraform state."
  value       = "environments/dev/terraform.tfstate"
}

output "production_state_key" {
  description = "Recommended S3 key for production Terraform state."
  value       = "environments/prod/terraform.tfstate"
}