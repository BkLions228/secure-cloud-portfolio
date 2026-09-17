variable "project_name" {
  description = "Project identifier used in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "bucket_name" {
  description = "Globally unique name for the private frontend S3 bucket."
  type        = string
}

variable "enable_versioning" {
  description = "Whether S3 object versioning is enabled."
  type        = bool
  default     = true
}

variable "default_root_object" {
  description = "Object CloudFront returns for requests to the distribution root."
  type        = string
  default     = "index.html"
}

variable "price_class" {
  description = "CloudFront edge-location price class."
  type        = string
  default     = "PriceClass_100"
}

# variable "minimum_protocol_version" {
#   description = "Minimum TLS protocol version."
#   type        = string
#   default     = "TLSv1.2_2021"
# }

variable "enable_ipv6" {
  description = "Whether the CloudFront distribution supports IPv6."
  type        = bool
  default     = true
}

variable "cloudfront_comment" {
  description = "Description assigned to the CloudFront distribution."
  type        = string
  default     = "Secure cloud portfolio static site"
}