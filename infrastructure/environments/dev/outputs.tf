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
output "monitoring_sns_topic_arn" {
  description = "SNS topic used for development monitoring alerts."
  value       = module.monitoring.sns_topic_arn
}

output "monitoring_alarm_names" {
  description = "CloudWatch alarms protecting the development environment."
  value       = module.monitoring.alarm_names
}

output "monitoring_dashboard_name" {
  description = "CloudWatch operations dashboard for the development environment."
  value       = module.monitoring.dashboard_name
}
