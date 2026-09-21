# Policy-as-Code Security Guardrails — Validation Evidence

## Scanner

- Tool: Checkov
- Version: 3.3.19
- Terraform framework
- CloudFormation framework
- Enforcement model: applicable security controls fail CI; architecture-specific findings require documented technical disposition

## Initial Baseline

Initial combined static-analysis baseline:

- Passed: 85
- Failed: 26
- Skipped: 0

The initial baseline was used to identify actionable security gaps while separating architecture-specific recommendations, deferred enhancements, and non-applicable controls.

Raw Checkov pass/fail totals are not treated as a security score. Resource additions and architecture changes can increase the number of evaluated checks even when the security posture improves.

## Implemented Remediations

### API Gateway Access Logging

Structured API Gateway access logging was added using a dedicated CloudWatch Logs group.

Controls include:

- 30-day retention
- Structured JSON access records
- Detailed API metrics
- Development environment stage variable
- No source IP field in the configured log format

Source IP was intentionally omitted to reduce unnecessary collection of visitor network identifiers.

### Lambda Log Retention

The existing Lambda log groups were operationally validated with 30-day retention:

- `/aws/lambda/secure-cloud-portfolio-dev-health`
- `/aws/lambda/secure-cloud-portfolio-dev-visitor-counter`

These log groups predated explicit CloudFormation management. Attempts to add them as new `AWS::Logs::LogGroup` resources triggered CloudFormation `NAME_CONFLICT_VALIDATION` because the physical resources already existed.

The existing production log groups were preserved rather than deleted solely to force CloudFormation ownership.

### Lambda Reserved Concurrency Exception

Checkov `CKV_AWS_115` recommends function-level concurrency limits.

Reserved concurrency of 5 was initially tested on both Lambda functions. Deployment failed because the AWS account has:

- Regional concurrent execution quota: 10
- Unreserved concurrent executions: 10

AWS rejected the configuration because assigning reserved concurrency would reduce the account's unreserved concurrency below the required minimum of 10.

CloudFormation automatically rolled the attempted deployment back to `UPDATE_ROLLBACK_COMPLETE`.

The reserved-concurrency configuration was therefore removed and `CKV_AWS_115` was classified as a documented architecture/account-quota exception rather than an enforced CI control.

This exception should be reconsidered if the Lambda regional concurrency quota is increased.

### CloudFront Access Logging

A dedicated S3 bucket was added for CloudFront access logging with:

- S3 Block Public Access
- SSE-S3 encryption
- Versioning
- Lifecycle retention
- Noncurrent-version expiration
- Incomplete multipart upload cleanup
- Dedicated `cloudfront/` object prefix

CloudFront logging configuration was validated through the AWS API.

Physical S3 log-object delivery remained pending during the initial operational validation and should not be represented as validated until log objects are observed in the destination bucket.

## Terraform Static Analysis

Post-remediation Terraform Checkov result:

- Passed: 90
- Failed: 19
- Skipped: 0

Validated controls include:

- S3 Block Public Access
- S3 encryption at rest
- S3 versioning
- CloudFront HTTPS enforcement
- CloudFront access logging configuration
- CloudFront origin access protection
- IAM least-privilege checks
- GitHub Actions OIDC safe claims
- Lifecycle management

Remaining Terraform findings are reviewed individually rather than treated as an aggregate security score.

## SAM / CloudFormation Static Analysis

Final full SAM / CloudFormation assessment:

- Passed: 8
- Failed: 9
- Skipped: 0

The broader assessment intentionally reports recommendations that are not all part of the enforced portfolio baseline.

### Enforced SAM Baseline

Applicable CI-enforced SAM controls:

- `CKV_AWS_28` — DynamoDB point-in-time recovery
- `CKV_AWS_45` — No hard-coded Lambda secrets
- `CKV_AWS_66` — CloudWatch log retention
- `CKV_AWS_95` — API Gateway V2 access logging
- `CKV_AWS_363` — Supported Lambda runtime

Local enforcement result:

- Passed: 7
- Failed: 0
- Skipped: 0

### Remaining SAM Findings

| Check | Resources | Disposition | Rationale |
|---|---|---|---|
| CKV_AWS_119 | DynamoDB visitor table | Deferred | DynamoDB encryption is enabled. Customer-managed KMS is an additional control that is not required for the current portfolio risk profile. |
| CKV_AWS_158 | API access log group | Deferred | CloudWatch Logs data is encrypted at rest. Customer-managed KMS remains a future strengthening option. |
| CKV_AWS_116 | Health and visitor Lambda functions | Not Applicable | These functions service synchronous API Gateway requests. Lambda DLQs primarily address failed asynchronous invocation records and are not the primary failure-handling mechanism for this request path. |
| CKV_AWS_115 | Health and visitor Lambda functions | Documented Exception | The AWS account concurrency quota is 10 with 10 unreserved executions. AWS rejected reserved concurrency because it would reduce unreserved concurrency below the required minimum. |
| CKV_AWS_117 | Health and visitor Lambda functions | Not Applicable | Neither function requires private VPC resources. VPC attachment solely to satisfy a scanner would add unnecessary networking complexity. |
| CKV_AWS_173 | Visitor Lambda | Risk Accepted | `VISITOR_TABLE_NAME` contains resource configuration rather than secret material. Customer-managed KMS can be added if sensitive environment values are introduced later. |

These dispositions are architecture-specific decisions and do not represent blanket exceptions for future workloads.

## Negative Policy Tests

Intentionally insecure fixtures were used to verify that the policy engine rejects known-bad configurations.

### Terraform Negative Test

The insecure S3 fixture intentionally disables S3 Block Public Access protections.

Result:

- Passed checks: 0
- Failed checks: 4
- Checkov exit code: 1
- Failed controls: `CKV_AWS_53`, `CKV_AWS_54`, `CKV_AWS_55`, `CKV_AWS_56`

Expected result: policy violation detected.

### SAM Negative Test

The insecure API fixture intentionally defines an API Gateway V2/SAM HTTP API without required access logging.

Result:

- Passed checks: 0
- Failed checks: 1
- Skipped checks: 0
- Checkov exit code: 1
- Failed control: `CKV_AWS_95`

Expected result: policy violation detected.

This negative test directly validates a control that remains part of the production CI enforcement baseline.

### Automated Negative-Test Harness

`policy/tests/run-negative-tests.sh` successfully confirmed that intentionally insecure configurations were rejected.

Harness result:

```text
ALL NEGATIVE POLICY TESTS PASSED
All intentionally insecure configurations were blocked.
```

Harness exit code: 0.

## Runtime Validation

### CloudFormation Deployment

Final SAM security deployment completed successfully:

```text
secure-cloud-portfolio-dev-api
UPDATE_COMPLETE
```

The final reviewed change set contained only:

- Add `VisitorApiAccessLogGroup`
- Modify `VisitorApiStage`
- No resource replacement
- No DynamoDB modification
- No Lambda modification
- No deletion

### API Gateway Access Logging

Runtime validation confirmed:

- Access-log destination configured
- Structured JSON format configured
- Detailed metrics enabled
- `Environment=dev` stage variable configured
- API access-log retention: 30 days

Observed runtime events:

```text
GET /health    -> 200
POST /visitor  -> 200
```

The configured access-log format intentionally excludes source IP.

### Application Validation

Health endpoint returned:

```json
{"status": "healthy"}
```

Visitor API returned a valid incremented counter.

A strongly consistent DynamoDB read confirmed that the stored counter matched the API response during validation.

Subsequent validation incremented the page-view counter to 12.

### Lambda Logging

Operational validation confirmed:

```text
/aws/lambda/secure-cloud-portfolio-dev-health           30 days
/aws/lambda/secure-cloud-portfolio-dev-visitor-counter  30 days
```

### CloudFront Infrastructure

AWS runtime validation confirmed:

- CloudFront logging enabled
- Dedicated CloudFront logging bucket exists
- Logging bucket versioning enabled
- Logging bucket SSE-S3 encryption enabled
- All four S3 Block Public Access settings enabled
- Existing portfolio bucket retained restricted CloudFront read access
- Existing portfolio bucket retained `DenyInsecureTransport`
- CloudFront portfolio continued returning HTTP 200
- Terraform post-deployment plan reported no configuration drift

Physical CloudFront access-log object delivery remains pending evidence until an object is observed in the logging bucket.

## Deployment Incidents and Corrective Actions

### Existing Lambda Log-Group Ownership Conflict

CloudFormation Early Validation rejected explicit Lambda log-group resources because the named log groups already existed.

Corrective action:

- Existing production log groups were preserved.
- Their 30-day retention was validated operationally.
- Explicit CloudFormation creation of those pre-existing resources was removed.
- The new API Gateway access-log group remained IaC-managed.

### Lambda Reserved-Concurrency Rollback

An attempted deployment configured reserved concurrency of 5 on each Lambda function.

AWS rejected both updates because the account concurrency quota is 10 and the configuration would reduce unreserved concurrency below AWS's required minimum.

CloudFormation successfully rolled back the attempted update.

Corrective action:

- Reserved concurrency was removed.
- `CKV_AWS_115` was removed from the production enforcement baseline.
- The finding remains visible in full Checkov assessments.
- The exception is supported by AWS runtime quota evidence.

## Risk-Based Exceptions

Scanner findings are not treated as automatic deployment failures without architectural analysis.

Examples include:

- Customer-managed KMS enhancements
- Cross-region S3 replication
- S3 event notifications
- Recursive server-access logging on a logging destination bucket
- Lambda VPC placement without private network dependencies
- Lambda DLQs for synchronous HTTP request paths
- Lambda reserved concurrency when prevented by account quota
- CloudFront geographic restrictions
- CloudFront origin failover
- WAF
- Custom TLS certificate before custom-domain implementation

Each finding requires a documented technical disposition rather than blind remediation.

## Evidence Chain

```text
Infrastructure as Code
        |
        v
Full Static Policy Assessment
        |
        v
Applicable Enforcement Baseline
        |
        v
Negative Policy Testing
        |
        v
Reviewed Change Set
        |
        v
AWS Deployment
        |
        v
AWS CLI Runtime Validation
        |
        v
Drift / Application Validation
        |
        v
GitHub Pull Request Policy Gate
```

The final GitHub Actions run ID and pull request evidence will be added after CI validation.