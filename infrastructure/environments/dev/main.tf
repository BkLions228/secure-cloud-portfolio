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

  github_organization = var.github_organization
  github_repository   = var.github_repository
  github_branch       = var.github_deployment_branch

  role_name = "${var.project_name}-${var.environment}-github-deploy"

  site_bucket_name = module.static_site.site_bucket_name

  cloudfront_distribution_arn = (
    module.static_site.cloudfront_distribution_arn
  )
}