output "sns_topic_arn" {
  description = "SNS topic ARN used for operational monitoring alerts."
  value       = aws_sns_topic.monitoring_alerts.arn
}

output "alarm_names" {
  description = "CloudWatch alarm names created by the monitoring module."
  value = [
    aws_cloudwatch_metric_alarm.cloudfront_5xx_error_rate.alarm_name,
    aws_cloudwatch_metric_alarm.api_5xx.alarm_name,
    aws_cloudwatch_metric_alarm.api_log_server_errors.alarm_name,
    aws_cloudwatch_metric_alarm.api_latency.alarm_name,
    aws_cloudwatch_metric_alarm.health_lambda_errors.alarm_name,
    aws_cloudwatch_metric_alarm.health_lambda_throttles.alarm_name,
    aws_cloudwatch_metric_alarm.visitor_lambda_errors.alarm_name,
    aws_cloudwatch_metric_alarm.visitor_lambda_throttles.alarm_name,
    aws_cloudwatch_metric_alarm.visitor_lambda_duration.alarm_name,
    aws_cloudwatch_metric_alarm.dynamodb_system_errors.alarm_name
  ]
}

output "dashboard_name" {
  description = "CloudWatch operations dashboard name."
  value       = aws_cloudwatch_dashboard.operations.dashboard_name
}
