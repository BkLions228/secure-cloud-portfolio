locals {
  origin_id = "${var.project_name}-${var.environment}-s3-origin"
}

resource "aws_s3_bucket" "site" {
  bucket = var.bucket_name

  tags = {
    Name               = var.bucket_name
    Purpose            = "private-static-site-origin"
    DataClassification = "public"
  }
}

resource "aws_s3_bucket_ownership_controls" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "site" {
  bucket = aws_s3_bucket.site.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    id     = "manage-noncurrent-frontend-objects"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.site
  ]
}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_response_headers_policy" "security_headers" {
  name = "Managed-SecurityHeadersPolicy"
}

resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "${var.project_name}-${var.environment}-oac"
  description                       = "OAC for the private portfolio S3 origin"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_s3_bucket" "cloudfront_logs" {
  bucket = "${var.bucket_name}-cloudfront-logs"

  tags = {
    Name               = "${var.bucket_name}-cloudfront-logs"
    Purpose            = "cloudfront-access-logging"
    DataClassification = "operational"
  }
}

resource "aws_s3_bucket_ownership_controls" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  rule {
    id     = "expire-cloudfront-access-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.cloudfront_logs
  ]
}

resource "aws_s3_bucket_versioning" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  is_ipv6_enabled     = var.enable_ipv6
  comment             = var.cloudfront_comment
  default_root_object = var.default_root_object
  price_class         = var.price_class
  wait_for_deployment = true

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.cloudfront_logs.bucket_domain_name
    prefix          = "cloudfront/"
  }

  origin {
    domain_name                 = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                   = local.origin_id
    origin_access_control_id    = aws_cloudfront_origin_access_control.site.id
    response_completion_timeout = 0
  }

  default_cache_behavior {
    target_origin_id       = local.origin_id
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = [
      "GET",
      "HEAD",
      "OPTIONS"
    ]

    cached_methods = [
      "GET",
      "HEAD"
    ]

    cache_policy_id = data.aws_cloudfront_cache_policy.caching_optimized.id

    response_headers_policy_id = (
      data.aws_cloudfront_response_headers_policy.security_headers.id
    )

    compress = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name    = "${var.project_name}-${var.environment}-distribution"
    Purpose = "secure-static-site-delivery"
  }

  depends_on = [
    aws_s3_bucket_public_access_block.site,
    aws_s3_bucket_ownership_controls.site,
    aws_s3_bucket_ownership_controls.cloudfront_logs,
    aws_s3_bucket_public_access_block.cloudfront_logs
  ]
}

data "aws_iam_policy_document" "site" {
  statement {
    sid    = "AllowCloudFrontServicePrincipalReadOnly"
    effect = "Allow"

    principals {
      type = "Service"

      identifiers = [
        "cloudfront.amazonaws.com"
      ]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.site.arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"

      values = [
        aws_cloudfront_distribution.site.arn
      ]
    }
  }

  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type = "*"

      identifiers = [
        "*"
      ]
    }

    actions = [
      "s3:*"
    ]

    resources = [
      aws_s3_bucket.site.arn,
      "${aws_s3_bucket.site.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"

      values = [
        "false"
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.site.json

  depends_on = [
    aws_s3_bucket_public_access_block.site
  ]
}