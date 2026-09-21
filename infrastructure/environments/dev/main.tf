module "static_site" {
  source = "../../modules/static-site"

  project_name      = var.project_name
  environment       = var.environment
  bucket_name       = var.site_bucket_name
  enable_versioning = var.enable_versioning
  price_class       = var.price_class

  cloudfront_comment = (
    "${var.project_name} ${var.environment} static portfolio"
  )


}

module "github_oidc" {
  source = "../../modules/github-oidc"

  github_organization    = var.github_organization
  github_organization_id = var.github_organization_id
  github_repository      = var.github_repository
  github_repository_id   = var.github_repository_id
  github_branch          = var.github_deployment_branch

  role_name = "${var.project_name}-${var.environment}-github-deploy"

  site_bucket_name = module.static_site.site_bucket_name

  cloudfront_distribution_arn = (
    module.static_site.cloudfront_distribution_arn
  )
}

module "github_backend_deploy" {
  source = "../../modules/github-backend-deploy"

  github_oidc_provider_arn = module.github_oidc.oidc_provider_arn

  github_organization    = var.github_organization
  github_organization_id = var.github_organization_id
  github_repository      = var.github_repository
  github_repository_id   = var.github_repository_id
  github_branch          = var.github_deployment_branch

  role_name = "${var.project_name}-${var.environment}-github-backend-deploy"

  project_name = var.project_name
  environment  = var.environment
}
module "monitoring" {
  source = "../../modules/monitoring"

  project_name = var.project_name
  environment  = var.environment

  cloudfront_distribution_id = (
    module.static_site.cloudfront_distribution_id
  )

  api_gateway_id    = var.api_gateway_id
  api_gateway_stage = var.environment

  api_access_log_group_name = (
    "/aws/apigateway/${var.project_name}-${var.environment}-visitor-api"
  )

  health_function_name = (
    "${var.project_name}-${var.environment}-health"
  )

  visitor_function_name = (
    "${var.project_name}-${var.environment}-visitor-counter"
  )

  dynamodb_table_name = (
    "${var.project_name}-${var.environment}-visitors"
  )

  tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.owner
    ManagedBy   = "Terraform"
    Purpose     = "monitoring-observability"
  }
}
