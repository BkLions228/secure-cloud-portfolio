output "site_bucket_name" {
  description = "Name of the private frontend S3 bucket."
  value       = aws_s3_bucket.site.id
}

output "site_bucket_arn" {
  description = "ARN of the private frontend S3 bucket."
  value       = aws_s3_bucket.site.arn
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution identifier."
  value       = aws_cloudfront_distribution.site.id
}

output "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN."
  value       = aws_cloudfront_distribution.site.arn
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name."
  value       = aws_cloudfront_distribution.site.domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "CloudFront hosted-zone ID for future Route 53 alias records."
  value       = aws_cloudfront_distribution.site.hosted_zone_id
}

output "origin_access_control_id" {
  description = "CloudFront Origin Access Control identifier."
  value       = aws_cloudfront_origin_access_control.site.id
}