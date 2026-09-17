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