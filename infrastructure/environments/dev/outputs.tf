output "site_bucket_name" {
  description = "Name of the development frontend bucket."
  value       = module.static_site.site_bucket_name
}

output "cloudfront_distribution_id" {
  description = "Development CloudFront distribution ID."
  value       = module.static_site.cloudfront_distribution_id
}

output "cloudfront_domain_name" {
  description = "Development CloudFront distribution domain."
  value       = module.static_site.cloudfront_domain_name
}

output "portfolio_url" {
  description = "Development portfolio URL."
  value       = "https://${module.static_site.cloudfront_domain_name}"
}
output "github_actions_role_arn" {
  description = "IAM role ARN used by GitHub Actions for frontend deployment."
  value       = module.github_oidc.role_arn
}