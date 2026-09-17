output "role_name" {
  description = "Name of the IAM role assumed by GitHub Actions."
  value       = aws_iam_role.github_actions.name
}

output "role_arn" {
  description = "ARN of the IAM role assumed by GitHub Actions."
  value       = aws_iam_role.github_actions.arn
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub Actions IAM OIDC provider."
  value       = aws_iam_openid_connect_provider.github_actions.arn
}

output "deployment_policy_arn" {
  description = "ARN of the least-privilege frontend deployment policy."
  value       = aws_iam_policy.deployment.arn
}