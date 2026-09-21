# Policy-as-Code Security Guardrails

## Purpose

This directory contains the automated security policy framework for the Secure Cloud Portfolio Platform.

The policy-as-code implementation uses Checkov to evaluate Terraform and AWS SAM/CloudFormation infrastructure before changes are accepted through the GitHub pull-request workflow.

The objective is not to force every scanner recommendation into the architecture. Instead, the framework distinguishes between:

- Enforced security requirements
- Architecture-specific exceptions
- Accepted risks
- Deferred security enhancements
- Non-applicable recommendations

This approach combines automated preventive controls with documented engineering and GRC analysis.

## Tooling

- Checkov 3.3.19
- Terraform
- AWS SAM / CloudFormation
- GitHub Actions
- Bash negative-test harness

Python dependencies are pinned in:

`policy/requirements.txt`

## Enforcement Model

The security pipeline evaluates infrastructure in three layers:

```text
Infrastructure as Code
        |
        v
Static Security Analysis
        |
        v
Applicable Policy Baseline
        |
        v
Negative Security Tests
        |
        v
Pull Request Validation
```

Full Checkov scans may identify recommendations beyond the requirements of the current architecture.

CI enforcement therefore uses an explicit set of controls that have been reviewed for applicability to this workload.

A scanner finding that is not included in the enforced baseline must still receive an appropriate technical disposition when relevant.

## Policy Control Baseline

| ID | Security Control | Implementation |
|---|---|---|
| PAC-001 | S3 public access blocked | Terraform / Checkov |
| PAC-002 | S3 server-side encryption | Terraform / Checkov |
| PAC-003 | S3 versioning | Terraform / Checkov |
| PAC-004 | CloudFront HTTP-to-HTTPS redirect | Terraform / Checkov |
| PAC-005 | Private S3 origin through CloudFront OAC | Terraform / Checkov |
| PAC-006 | Dangerous IAM wildcard permissions prohibited | Terraform / Checkov |
| PAC-007 | GitHub OIDC trust restricted to expected repository and branch | Terraform / Checkov |
| PAC-008 | DynamoDB encryption | SAM / AWS service encryption |
| PAC-009 | DynamoDB point-in-time recovery | SAM / Checkov |
| PAC-010 | DynamoDB destructive-change protection | SAM architecture / deployment review |
| PAC-011 | Lambda IAM limited to required DynamoDB action and resource | SAM |
| PAC-012 | Required governance tags | Terraform / SAM |
| PAC-013 | Infrastructure policy validation in CI | GitHub Actions |
| PAC-014 | API Gateway access logging | SAM / Checkov |
| PAC-015 | Lambda reserved concurrency | Documented exception under current AWS account quota |
| PAC-016 | 30-day operational log retention | SAM for API logs; operational validation for existing Lambda logs |
| PAC-017 | CORS restricted to approved frontend origin | SAM |
| PAC-018 | CloudFront access logging and retention | Terraform |

## Terraform Enforcement Baseline

The GitHub Actions policy workflow evaluates applicable Terraform controls including:

- S3 encryption
- S3 versioning
- S3 Block Public Access
- CloudFront HTTPS enforcement
- CloudFront access logging
- IAM policy safety
- GitHub OIDC claim restrictions
- Private S3 access controls

The full Checkov assessment is retained separately as security evidence so non-enforced recommendations remain visible.

## SAM / CloudFormation Enforcement Baseline

The production SAM baseline currently enforces:

- `CKV_AWS_28` — DynamoDB point-in-time recovery
- `CKV_AWS_45` — No hard-coded Lambda secrets
- `CKV_AWS_66` — CloudWatch log retention
- `CKV_AWS_95` — API Gateway V2 access logging
- `CKV_AWS_363` — Supported Lambda runtime

## Reserved-Concurrency Exception

`CKV_AWS_115` recommends function-level concurrency limits.

Reserved concurrency was evaluated for both Lambda functions. An attempted configuration of five reserved executions per function was rejected because the AWS account has a regional concurrency quota of 10 with all 10 executions available as unreserved concurrency.

AWS rejected the configuration because assigning reserved concurrency would reduce the account's unreserved concurrency below the service-required minimum.

CloudFormation automatically rolled the attempted deployment back.

Therefore:

- Reserved concurrency is not configured.
- `CKV_AWS_115` remains visible during full security assessment.
- `CKV_AWS_115` is not part of the production CI enforcement baseline.
- The exception should be reconsidered if the regional concurrency quota is increased.

This prevents a scanner recommendation from driving an invalid production configuration.

## Log Management

### API Gateway

API Gateway access logging is managed through AWS SAM.

Controls include:

- Dedicated CloudWatch Logs group
- 30-day retention
- Structured JSON records
- Detailed metrics
- Source IP intentionally excluded from the access-log format

### Lambda

Existing Lambda log groups are configured for 30-day retention.

The groups existed before explicit CloudFormation log-group management was introduced. CloudFormation therefore could not create resources using the same physical names.

Rather than delete operational logs solely to transfer ownership, the existing groups were preserved and their retention configuration was validated through the AWS API.

### CloudFront

CloudFront access logging uses a dedicated S3 bucket with:

- Block Public Access
- SSE-S3 encryption
- Versioning
- Lifecycle retention
- Noncurrent-version expiration
- Incomplete multipart upload cleanup

CloudFront access logs may contain client network and request information. Their retention should therefore remain limited to the defined operational requirement.

## Negative Security Testing

The repository contains intentionally insecure infrastructure fixtures under:

`policy/tests/fixtures/fail/`

These resources must never be deployed.

Their only purpose is to prove that the policy engine detects configurations that violate the enforced security baseline.

### Terraform Negative Test

`insecure-s3.tf` intentionally disables S3 Block Public Access controls.

Expected failures:

- `CKV_AWS_53`
- `CKV_AWS_54`
- `CKV_AWS_55`
- `CKV_AWS_56`

### SAM Negative Test

`insecure-api.yaml` intentionally defines an API Gateway V2/SAM HTTP API without required access logging.

Expected failure:

- `CKV_AWS_95`

This negative test directly validates a control that remains part of the production CI enforcement baseline.

## Running Negative Tests

From the repository root:

```bash
./policy/tests/run-negative-tests.sh
```

Individual Checkov scans inside the harness are expected to fail because the fixtures are intentionally insecure.

The wrapper succeeds only when all insecure fixtures are rejected.

Expected result:

```text
ALL NEGATIVE POLICY TESTS PASSED
All intentionally insecure configurations were blocked.
```

The expected harness exit code is `0`.

If an intentionally insecure configuration passes Checkov, the harness returns a nonzero exit code and CI fails.

## Local Production Policy Validation

Terraform:

```bash
checkov \
  -d infrastructure \
  --framework terraform \
  --compact \
  --download-external-modules false \
  --check CKV_AWS_19,CKV_AWS_21,CKV_AWS_34,CKV_AWS_53,CKV_AWS_54,CKV_AWS_55,CKV_AWS_56,CKV_AWS_63,CKV_AWS_86,CKV_AWS_274,CKV_AWS_358,CKV_AWS_393,CKV2_AWS_6,CKV2_AWS_46
```

SAM / CloudFormation:

```bash
checkov \
  -f backend/template.yaml \
  --framework cloudformation \
  --compact \
  --check CKV_AWS_28,CKV_AWS_45,CKV_AWS_66,CKV_AWS_95,CKV_AWS_363
```

## Risk Treatment Philosophy

Policy-as-code findings require technical context.

The project does not automatically implement a scanner recommendation when doing so would conflict with AWS service constraints, add unnecessary infrastructure, increase cost without proportionate risk reduction, introduce unnecessary network complexity, disrupt functioning resources, or implement a control intended for a different architecture.

Findings are categorized as:

- Remediated
- Enforced
- Risk accepted
- Deferred
- Not applicable
- Documented exception

This provides both engineering evidence and governance traceability.

## Evidence

Detailed validation evidence is maintained in:

`docs/evidence/policy-as-code/README.md`

The evidence includes static analysis, negative security testing, AWS runtime validation, deployment rollback analysis, log-retention validation, risk decisions, and CI results.

## Security Rule

Files under `policy/tests/fixtures/fail/` are intentionally insecure test resources.

They must never be used as deployment templates or copied into production infrastructure.
