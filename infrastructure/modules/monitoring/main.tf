locals {
  name_prefix = "${var.project_name}-${var.environment}"

  alarm_actions = [
    aws_sns_topic.monitoring_alerts.arn
  ]
}

resource "aws_sns_topic" "monitoring_alerts" {
  name = "${local.name_prefix}-monitoring-alerts"

  tags = merge(
    var.tags,
    {
      Name    = "${local.name_prefix}-monitoring-alerts"
      Purpose = "operational-monitoring"
    }
  )
}

#
# CloudFront
#

resource "aws_cloudwatch_metric_alarm" "cloudfront_5xx_error_rate" {
  alarm_name          = "${local.name_prefix}-cloudfront-5xx-error-rate"
  alarm_description   = "CloudFront 5xx error rate is at or above 5 percent."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 5
  metric_name         = "5xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 300
  statistic           = "Average"

  dimensions = {
    DistributionId = var.cloudfront_distribution_id
    Region         = "Global"
  }

  treat_missing_data = "notBreaching"
  alarm_actions      = local.alarm_actions
  ok_actions         = local.alarm_actions

  tags = var.tags
}

#
# API Gateway HTTP API
#

resource "aws_cloudwatch_metric_alarm" "api_5xx" {
  alarm_name          = "${local.name_prefix}-api-5xx"
  alarm_description   = "API Gateway returned one or more 5xx responses."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1
  metric_name         = "5xx"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"

  dimensions = {
    ApiId = var.api_gateway_id
    Stage = var.api_gateway_stage
  }

  treat_missing_data = "notBreaching"
  alarm_actions      = local.alarm_actions
  ok_actions         = local.alarm_actions

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "api_latency" {
  alarm_name          = "${local.name_prefix}-api-latency"
  alarm_description   = "API Gateway average latency is at or above 2000 milliseconds."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  threshold           = 2000
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Average"

  dimensions = {
    ApiId = var.api_gateway_id
    Stage = var.api_gateway_stage
  }

  treat_missing_data = "notBreaching"
  alarm_actions      = local.alarm_actions
  ok_actions         = local.alarm_actions

  tags = var.tags
}

#
# Lambda - Health
#

resource "aws_cloudwatch_metric_alarm" "health_lambda_errors" {
  alarm_name          = "${local.name_prefix}-health-lambda-errors"
  alarm_description   = "Health Lambda produced one or more errors."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"

  dimensions = {
    FunctionName = var.health_function_name
  }

  treat_missing_data = "notBreaching"
  alarm_actions      = local.alarm_actions
  ok_actions         = local.alarm_actions

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "health_lambda_throttles" {
  alarm_name          = "${local.name_prefix}-health-lambda-throttles"
  alarm_description   = "Health Lambda experienced one or more throttled invocations."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"

  dimensions = {
    FunctionName = var.health_function_name
  }

  treat_missing_data = "notBreaching"
  alarm_actions      = local.alarm_actions
  ok_actions         = local.alarm_actions

  tags = var.tags
}

#
# Lambda - Visitor Counter
#

resource "aws_cloudwatch_metric_alarm" "visitor_lambda_errors" {
  alarm_name          = "${local.name_prefix}-visitor-lambda-errors"
  alarm_description   = "Visitor counter Lambda produced one or more errors."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"

  dimensions = {
    FunctionName = var.visitor_function_name
  }

  treat_missing_data = "notBreaching"
  alarm_actions      = local.alarm_actions
  ok_actions         = local.alarm_actions

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "visitor_lambda_throttles" {
  alarm_name          = "${local.name_prefix}-visitor-lambda-throttles"
  alarm_description   = "Visitor counter Lambda experienced one or more throttled invocations."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"

  dimensions = {
    FunctionName = var.visitor_function_name
  }

  treat_missing_data = "notBreaching"
  alarm_actions      = local.alarm_actions
  ok_actions         = local.alarm_actions

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "visitor_lambda_duration" {
  alarm_name          = "${local.name_prefix}-visitor-lambda-duration"
  alarm_description   = "Visitor counter Lambda average duration is at or above 3000 milliseconds."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  threshold           = 3000
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Average"

  dimensions = {
    FunctionName = var.visitor_function_name
  }

  treat_missing_data = "notBreaching"
  alarm_actions      = local.alarm_actions
  ok_actions         = local.alarm_actions

  tags = var.tags
}

#
# DynamoDB
#

resource "aws_cloudwatch_metric_alarm" "dynamodb_system_errors" {
  alarm_name          = "${local.name_prefix}-dynamodb-system-errors"
  alarm_description   = "DynamoDB reported one or more system errors."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1
  metric_name         = "SystemErrors"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"

  dimensions = {
    TableName = var.dynamodb_table_name
  }

  treat_missing_data = "notBreaching"
  alarm_actions      = local.alarm_actions
  ok_actions         = local.alarm_actions

  tags = var.tags
}

#
# CloudWatch Operations Dashboard
#

resource "aws_cloudwatch_dashboard" "operations" {
  dashboard_name = "${local.name_prefix}-operations"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 2

        properties = {
          markdown = "# Secure Cloud Portfolio - ${upper(var.environment)} Operations\nCloudFront, API Gateway, Lambda, and DynamoDB operational health."
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 2
        width  = 12
        height = 6

        properties = {
          title   = "CloudFront Requests and Error Rates"
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          period  = 300

          metrics = [
            [
              "AWS/CloudFront",
              "Requests",
              "DistributionId",
              var.cloudfront_distribution_id,
              "Region",
              "Global",
              {
                stat = "Sum"
              }
            ],
            [
              ".",
              "4xxErrorRate",
              ".",
              ".",
              ".",
              ".",
              {
                stat  = "Average"
                yAxis = "right"
              }
            ],
            [
              ".",
              "5xxErrorRate",
              ".",
              ".",
              ".",
              ".",
              {
                stat  = "Average"
                yAxis = "right"
              }
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 2
        width  = 12
        height = 6

        properties = {
          title   = "API Gateway Requests and Errors"
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          period  = 300

          metrics = [
            [
              "AWS/ApiGateway",
              "Count",
              "ApiId",
              var.api_gateway_id,
              "Stage",
              var.api_gateway_stage,
              {
                stat = "Sum"
              }
            ],
            [
              ".",
              "4xx",
              ".",
              ".",
              ".",
              ".",
              {
                stat = "Sum"
              }
            ],
            [
              ".",
              "5xx",
              ".",
              ".",
              ".",
              ".",
              {
                stat = "Sum"
              }
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 8
        width  = 12
        height = 6

        properties = {
          title   = "API Gateway Latency"
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          period  = 300

          metrics = [
            [
              "AWS/ApiGateway",
              "Latency",
              "ApiId",
              var.api_gateway_id,
              "Stage",
              var.api_gateway_stage,
              {
                stat = "Average"
              }
            ],
            [
              ".",
              "IntegrationLatency",
              ".",
              ".",
              ".",
              ".",
              {
                stat = "Average"
              }
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 8
        width  = 12
        height = 6

        properties = {
          title   = "Lambda Invocations"
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          period  = 300

          metrics = [
            [
              "AWS/Lambda",
              "Invocations",
              "FunctionName",
              var.health_function_name,
              {
                stat = "Sum"
              }
            ],
            [
              ".",
              ".",
              ".",
              var.visitor_function_name,
              {
                stat = "Sum"
              }
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 14
        width  = 12
        height = 6

        properties = {
          title   = "Lambda Errors and Throttles"
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          period  = 300

          metrics = [
            [
              "AWS/Lambda",
              "Errors",
              "FunctionName",
              var.health_function_name,
              {
                stat = "Sum"
              }
            ],
            [
              ".",
              "Throttles",
              ".",
              ".",
              {
                stat = "Sum"
              }
            ],
            [
              ".",
              "Errors",
              ".",
              var.visitor_function_name,
              {
                stat = "Sum"
              }
            ],
            [
              ".",
              "Throttles",
              ".",
              ".",
              {
                stat = "Sum"
              }
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 14
        width  = 12
        height = 6

        properties = {
          title   = "Visitor Lambda Duration"
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          period  = 300

          metrics = [
            [
              "AWS/Lambda",
              "Duration",
              "FunctionName",
              var.visitor_function_name,
              {
                stat = "Average"
              }
            ],
            [
              "...",
              {
                stat = "Maximum"
              }
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 20
        width  = 12
        height = 6

        properties = {
          title   = "DynamoDB Requests and System Errors"
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          period  = 300

          metrics = [
            [
              "AWS/DynamoDB",
              "SuccessfulRequestLatency",
              "TableName",
              var.dynamodb_table_name,
              "Operation",
              "UpdateItem",
              {
                stat = "Average"
              }
            ],
            [
              "AWS/DynamoDB",
              "SystemErrors",
              "TableName",
              var.dynamodb_table_name,
              {
                stat = "Sum"
              }
            ]
          ]
        }
      },
      {
        type   = "alarm"
        x      = 12
        y      = 20
        width  = 12
        height = 6

        properties = {
          title = "Operational Alarm Status"

          alarms = [
            aws_cloudwatch_metric_alarm.cloudfront_5xx_error_rate.arn,
            aws_cloudwatch_metric_alarm.api_5xx.arn,
            aws_cloudwatch_metric_alarm.api_log_server_errors.arn,
            aws_cloudwatch_metric_alarm.api_latency.arn,
            aws_cloudwatch_metric_alarm.health_lambda_errors.arn,
            aws_cloudwatch_metric_alarm.health_lambda_throttles.arn,
            aws_cloudwatch_metric_alarm.visitor_lambda_errors.arn,
            aws_cloudwatch_metric_alarm.visitor_lambda_throttles.arn,
            aws_cloudwatch_metric_alarm.visitor_lambda_duration.arn,
            aws_cloudwatch_metric_alarm.dynamodb_system_errors.arn
          ]
        }
      }
    ]
  })
}

#

#
# Log-Based API Error Detection
#

resource "aws_cloudwatch_log_metric_filter" "api_server_errors" {
  name           = "${local.name_prefix}-api-server-errors"
  log_group_name = var.api_access_log_group_name

  pattern = "{ $.status >= 500 }"

  metric_transformation {
    name          = "ApiServerErrors"
    namespace     = "SecureCloudPortfolio/${var.environment}"
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

resource "aws_cloudwatch_metric_alarm" "api_log_server_errors" {
  alarm_name        = "${local.name_prefix}-api-log-server-errors"
  alarm_description = "API access logs recorded one or more HTTP 5xx responses."

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1

  metric_name = "ApiServerErrors"
  namespace   = "SecureCloudPortfolio/${var.environment}"
  period      = 300
  statistic   = "Sum"

  treat_missing_data = "notBreaching"

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = var.tags
}
