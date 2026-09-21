output "role_name" {
  description = "Backend deployment IAM role name."
  value       = aws_iam_role.github_backend_deploy.name
}

output "role_arn" {
  description = "Backend deployment IAM role ARN."
  value       = aws_iam_role.github_backend_deploy.arn
}

output "deployment_policy_arn" {
  description = "Backend deployment IAM policy ARN."
  value       = aws_iam_policy.github_backend_deploy.arn
}
