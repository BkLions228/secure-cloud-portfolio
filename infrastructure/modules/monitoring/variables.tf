variable "project_name" {
  description = "Project name used for monitoring resource naming."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "cloudfront_distribution_id" {
  description = "CloudFront distribution ID to monitor."
  type        = string
}

variable "api_gateway_id" {
  description = "API Gateway HTTP API ID to monitor."
  type        = string
}

variable "api_gateway_stage" {
  description = "API Gateway stage name."
  type        = string
}

variable "health_function_name" {
  description = "Health Lambda function name."
  type        = string
}

variable "visitor_function_name" {
  description = "Visitor counter Lambda function name."
  type        = string
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name to monitor."
  type        = string
}

variable "tags" {
  description = "Tags applied to supported monitoring resources."
  type        = map(string)
  default     = {}
}

variable "api_access_log_group_name" {
  description = "CloudWatch Logs group containing API Gateway access logs."
  type        = string
}
