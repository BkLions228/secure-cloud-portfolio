# Task 08 — Monitoring & Observability Evidence

## Objective

Implement production-oriented monitoring and observability for the Secure Cloud Portfolio Platform using Amazon CloudWatch, CloudWatch Logs, CloudWatch Alarms, Amazon SNS, and CloudFront access logging.

The monitoring design provides visibility across the frontend delivery tier, API tier, serverless compute tier, and persistence tier while providing centralized alert routing.

## Monitoring Architecture

The monitoring implementation covers:

- Amazon CloudFront
- Amazon API Gateway
- AWS Lambda
- Amazon DynamoDB
- Amazon CloudWatch Metrics
- Amazon CloudWatch Logs
- CloudWatch metric filters
- CloudWatch alarms
- CloudWatch dashboard
- Amazon SNS
- CloudFront access logs stored in Amazon S3

Monitoring resources are managed through the reusable Terraform monitoring module located at:

`infrastructure/modules/monitoring/`

The monitoring module observes serverless resources deployed separately through AWS SAM without attempting to take ownership of those resources.

## CloudWatch Operations Dashboard

Dashboard:

`secure-cloud-portfolio-dev-operations`

The dashboard provides centralized operational visibility for:

- CloudFront requests and HTTP error rates
- API Gateway requests and HTTP errors
- API Gateway latency and integration latency
- Lambda invocations
- Lambda errors
- Lambda throttles
- Visitor Lambda duration
- DynamoDB request latency and system errors
- CloudWatch alarm status

## CloudWatch Alarms

The following monitoring alarms were implemented:

1. CloudFront 5XX error rate
2. API Gateway 5XX errors
3. API Gateway latency
4. API access-log-derived server errors
5. Health Lambda errors
6. Health Lambda throttles
7. Visitor Lambda errors
8. Visitor Lambda throttles
9. Visitor Lambda duration
10. DynamoDB system errors

The development environment uses:

`treat_missing_data = "notBreaching"`

This prevents expected periods of low portfolio traffic from generating unnecessary alarms simply because no metric datapoints were produced.

## Log-Based API Error Detection

API Gateway access logs are written to:

`/aws/apigateway/secure-cloud-portfolio-dev-visitor-api`

Retention:

`30 days`

A CloudWatch Logs metric filter detects API server errors using:

`{ $.status >= 500 }`

Matching events publish the following custom metric:

- Namespace: `SecureCloudPortfolio/dev`
- Metric: `ApiServerErrors`
- Value: `1`

The custom metric is monitored by:

`secure-cloud-portfolio-dev-api-log-server-errors`

The alarm threshold is one or more detected server errors during the evaluation period.

### Metric Filter Validation

The filter was tested against synthetic HTTP status events.

Nonmatching events:

- HTTP 200
- HTTP 404

Matching events:

- HTTP 500
- HTTP 502
- HTTP 503

The AWS CloudWatch Logs test returned matches only for the 500, 502, and 503 events.

This validates the detection expression without intentionally introducing an application failure.

## SNS Alert Routing

Monitoring alarms route notifications through:

`secure-cloud-portfolio-dev-monitoring-alerts`

An email endpoint was operationally subscribed and confirmed outside the public Terraform configuration.

A controlled alarm-state test was used to validate the notification path without intentionally causing an application outage.

Validation path:

CloudWatch Alarm -> SNS -> Email

After testing, the alarm was returned to:

`OK`

with the reason:

`Controlled Task08 notification-path validation completed successfully`

The controlled state transition validates notification routing. It does not independently prove a real API failure would occur. Metric-filter behavior was therefore validated separately using CloudWatch Logs synthetic filter testing.

## CloudFront Access Logging

CloudFront distribution:

`E2TG4D3MO7U75H`

Access logging is enabled with:

- Include cookies: false
- Prefix: `cloudfront/`
- Dedicated S3 log bucket
- S3 server-side encryption
- S3 versioning
- S3 public access blocking
- Lifecycle management
- `BucketOwnerPreferred` object ownership

Physical log delivery was validated by observing CloudFront-generated `.gz` access-log objects under the configured `cloudfront/` prefix.

This closes the previous operational evidence gap where CloudFront logging was configured but physical object delivery had not yet been observed.

## Terraform Resource Validation

Terraform tracks 13 monitoring resources:

- 1 CloudWatch dashboard
- 10 CloudWatch metric alarms
- 1 CloudWatch Logs metric filter
- 1 SNS topic

The monitoring resources are managed under:

`module.monitoring`

## Infrastructure Drift Validation

A final Terraform plan was executed after deployment and operational testing.

Result:

`No changes. Your infrastructure matches the configuration.`

This confirms that the deployed AWS infrastructure matches the Terraform configuration after Task 08 validation.

## Windows Git Bash AWS CLI Observation

During CloudWatch Logs validation, AWS CLI commands using log-group paths beginning with `/aws/` exhibited path-handling behavior under Windows Git Bash/MSYS.

One Logs Insights request transformed the intended log-group path into a path beginning with:

`/Program Files/Git/aws/...`

This was a local shell path-conversion issue rather than evidence that the AWS log group was incorrectly configured.

The deployed metric filter was independently validated through AWS APIs and CloudWatch Logs metric-filter testing.

## Security and Governance Value

Task 08 adds detective controls to the preventive controls implemented earlier in the portfolio.

The monitoring architecture provides:

- centralized operational visibility
- serverless error detection
- latency monitoring
- throttling detection
- log-derived API error detection
- alert routing
- retained operational logs
- CloudFront request evidence
- infrastructure-as-code traceability
- controlled monitoring validation

Together, these capabilities demonstrate defense in depth by combining preventive policy-as-code guardrails with detective monitoring and operational response mechanisms.

## Validation Summary

Task 08 validation confirmed:

- Terraform configuration validation succeeded
- CloudWatch dashboard deployed successfully
- Ten CloudWatch alarms configured
- SNS alarm actions configured
- API Gateway access logging enabled
- API log retention configured for 30 days
- Log-derived API server-error metric deployed
- Synthetic 5XX detection test succeeded
- Controlled alarm notification-path test completed
- Alarm returned to OK after testing
- CloudFront logging enabled
- Physical CloudFront S3 log delivery observed
- Terraform monitoring state contains 13 resources
- Final Terraform plan reports zero infrastructure drift

## Result

Monitoring and observability are operational for the Secure Cloud Portfolio development environment.

The platform now includes infrastructure monitoring, application telemetry, log-based detection, centralized alerting, operational dashboards, retained access logs, and reproducible Terraform configuration suitable for continued DevSecOps and Cloud GRC development.
