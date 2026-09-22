# Automated CI/CD Pipeline Evidence

## Objective

Implement a secure automated CI/CD pipeline for the Secure Cloud Portfolio that validates infrastructure, application code, and security policy before deployment and uses GitHub Actions with AWS OIDC federation for backend deployment without long-lived AWS access keys.

## CI/CD Architecture

Feature Branch
    |
    v
Pull Request to main
    |
    +-- Python Unit Tests
    +-- Terraform Format and Validation
    +-- SAM Template Validation
    +-- Terraform Checkov Security Controls
    +-- SAM/CloudFormation Checkov Security Controls
    +-- Negative Policy-as-Code Tests
    |
    v
Approved Merge to main
    |
    +-- Frontend Deployment Workflow
    |
    +-- Backend Deployment Workflow
            |
            +-- Unit Tests
            +-- SAM Validate
            +-- SAM Build
            +-- GitHub OIDC Authentication
            +-- Assume AWS Deployment Role
            +-- SAM Deployment
            +-- CloudFormation Endpoint Discovery
            +-- Post-Deployment Health Validation

## GitHub Actions Workflows

### Policy-as-Code Workflow

File:

`.github/workflows/policy-as-code.yml`

The Policy-as-Code workflow runs on pull requests targeting `main` when changes affect:

- `infrastructure/**`
- `backend/**`
- `policy/**`
- `.github/workflows/**`

This ensures infrastructure, backend, policy, and CI/CD workflow modifications pass automated validation before merge.

### Backend Deployment Workflow

File:

`.github/workflows/deploy-backend.yml`

The backend deployment workflow is designed to execute when applicable backend changes reach `main`.

The workflow performs:

1. Repository checkout.
2. Python 3.10 configuration.
3. Backend dependency installation.
4. Backend unit testing.
5. AWS SAM CLI installation.
6. SAM template validation.
7. SAM application build.
8. AWS authentication through GitHub OIDC.
9. AWS caller identity verification.
10. AWS SAM deployment through CloudFormation.
11. Health endpoint discovery from CloudFormation outputs.
12. Post-deployment health validation.

## AWS Authentication

The backend deployment pipeline uses GitHub Actions OpenID Connect (OIDC) federation rather than persistent AWS access keys.

Deployment role:

`secure-cloud-portfolio-dev-github-backend-deploy`

The IAM trust relationship restricts role assumption to the expected GitHub repository and the `main` branch using immutable GitHub organization and repository identifiers.

The deployment policy is workload-scoped to resources required for the portfolio backend deployment. It does not contain an unrestricted `Action = "*"` statement.

## GitHub Repository Variables

The CI/CD environment uses the following GitHub repository variables:

- `AWS_BACKEND_DEPLOY_ROLE_ARN`
- `AWS_DEPLOY_ROLE_ARN`
- `CLOUDFRONT_DISTRIBUTION_ID`
- `PORTFOLIO_ORIGIN`
- `SAM_ARTIFACT_BUCKET`
- `SITE_BUCKET_NAME`

Environment-specific deployment configuration is separated from workflow logic.

No AWS access key or secret access key is used for GitHub Actions deployment authentication.

## Local Validation Evidence

### Backend Unit Tests

Result:

    3 passed

Validated behaviors include:

- Health endpoint handler.
- Visitor counter increment behavior.
- DynamoDB failure handling.

### Terraform Formatting

Command:

    terraform fmt -check -recursive infrastructure

Result:

    Exit code: 0

### Terraform Configuration Validation

Result:

    Success! The configuration is valid.

### Terraform Drift Validation

Result:

    No changes. Your infrastructure matches the configuration.

This confirms that the applied backend GitHub deployment IAM infrastructure matches the Terraform configuration.

### AWS SAM Validation

AWS SAM CLI version:

    1.163.0

Result:

    backend/template.yaml is a valid SAM Template

### AWS SAM Build

Result:

    Build Succeeded

The generated `.aws-sam` build directory remains excluded from Git.

## Policy-as-Code Validation

Checkov version:

    3.3.19

### Curated Terraform Security Gate

Result:

    Passed checks: 37
    Failed checks: 0
    Skipped checks: 0

The curated Terraform security baseline validates controls including:

- S3 public-access protection.
- S3 encryption.
- S3 versioning.
- HTTPS enforcement.
- CloudFront access logging.
- Private CloudFront-to-S3 access.
- IAM wildcard-action protection.
- GitHub OIDC trust restrictions.
- AdministratorAccess prevention.

### Curated SAM / CloudFormation Security Gate

Result:

    Passed checks: 7
    Failed checks: 0
    Skipped checks: 0

Validated controls include:

- DynamoDB point-in-time recovery.
- CloudWatch log retention.
- API Gateway access logging.
- Supported Lambda runtimes.
- Prevention of hard-coded Lambda secrets.

These results represent the project's curated CI security baseline. They do not imply that every Checkov policy available in a broad scan produces zero findings.

## Negative Policy Testing

The Policy-as-Code test harness intentionally evaluates insecure infrastructure to verify that preventive controls actually reject noncompliant configurations.

### Terraform Negative Test

Result:

    Passed checks: 0
    Failed checks: 4

The intentionally insecure S3 public-access configuration was correctly rejected.

### SAM Negative Test

Result:

    Passed checks: 0
    Failed checks: 1

The intentionally insecure HTTP API without required access logging was correctly rejected.

Final harness result:

    ALL NEGATIVE POLICY TESTS PASSED
    All intentionally insecure configurations were blocked.

## IAM Validation

The backend GitHub deployment module was inspected for unrestricted resource statements.

Result:

    PASS: no unrestricted Resource=* statement found

The curated Checkov controls also confirmed that the deployment IAM policy does not contain unrestricted wildcard actions and that the GitHub OIDC authorization policy uses restricted claims.

## CI/CD Production Validation

The automated backend CI/CD pipeline was validated through three controlled deployment attempts against the development AWS environment. The validation process demonstrated fail-fast CI behavior, GitHub OIDC federation, iterative least-privilege IAM hardening, automated deployment, and post-deployment verification.

### Deployment Attempt 1 — Dependency Validation Failure

GitHub Actions run `35657790386` failed during backend unit testing before AWS authentication or deployment occurred.

The clean GitHub-hosted runner identified an undeclared test dependency because `visitor_counter/app.py` imports `boto3`, while the development requirements initially contained only `pytest`.

Error:

```text
ModuleNotFoundError: No module named 'boto3'
```

The issue was remediated by explicitly adding `boto3>=1.35,<2.0` to `backend/requirements-dev.txt`.

This controlled failure demonstrated that the pipeline correctly prevented an incomplete build from reaching AWS.

### Deployment Attempt 2 — Least-Privilege IAM Failure

After the dependency remediation, GitHub Actions run `35660036655` successfully progressed through unit testing, SAM validation, SAM build, GitHub OIDC authentication, AWS identity verification, and SAM artifact upload.

The deployment was then blocked because the GitHub backend deployment role did not have permission to create a CloudFormation change set against the AWS SAM transform resource:

```text
arn:aws:cloudformation:us-east-1:aws:transform/Serverless-2016-10-31
```

Rather than granting unrestricted CloudFormation access, the IAM policy was updated with a dedicated statement allowing only:

```text
cloudformation:CreateChangeSet
```

against the required AWS SAM transform ARN.

The remediation was implemented through Terraform. Validation produced:

- Terraform configuration validation: passed.
- Terraform plan: `0 to add, 1 to change, 0 to destroy`.
- Curated Terraform Checkov gate: `37 passed, 0 failed, 0 skipped`.
- Unrestricted `Resource = "*"` validation: passed; none found.
- Terraform apply: `0 added, 1 changed, 0 destroyed`.
- Post-apply Terraform plan: no changes.
- AWS IAM policy verification: SAM-transform-specific permission present.

The Policy-as-Code pull-request validation for the remediation also completed successfully.

### Deployment Attempt 3 — Successful End-to-End Deployment

After the SAM transform remediation was merged into `main`, GitHub Actions run `35677110833` was deliberately initiated using the workflow's `workflow_dispatch` trigger.

The run executed against commit:

```text
b3fe23ee33788bbd776c2c870a3fd361b6cf7545
```

The complete `Test, Build, Deploy, and Validate` job succeeded in approximately 1 minute 31 seconds.

Validated stages included:

- Repository checkout.
- Python environment configuration.
- Backend dependency installation.
- Backend unit testing.
- AWS SAM CLI installation.
- SAM template validation.
- SAM application build.
- GitHub Actions OIDC authentication to AWS.
- AWS identity verification.
- Backend SAM deployment.
- CloudFormation output discovery.
- Post-deployment health validation.

No long-lived AWS access keys were required by the deployment workflow.

### Independent AWS Validation

The AWS environment was independently validated after the successful GitHub Actions deployment rather than relying solely on the workflow result.

CloudFormation stack:

```text
secure-cloud-portfolio-dev-api
```

Stack status:

```text
UPDATE_COMPLETE
```

Health endpoint:

```text
https://sqk3sg1oj5.execute-api.us-east-1.amazonaws.com/dev/health
```

An independent HTTP request returned:

```text
HTTP/1.1 200 OK
```

with the application response:

```json
{"status": "healthy"}
```

The visitor endpoint remained available at:

```text
https://sqk3sg1oj5.execute-api.us-east-1.amazonaws.com/dev/visitor
```

The health endpoint was intentionally used for deployment validation because it is non-mutating. Calling the visitor endpoint would increment the application's page-view counter.

### Infrastructure Drift Validation

A final Terraform plan was executed from:

```text
infrastructure/environments/dev
```

Terraform reported:

```text
No changes. Your infrastructure matches the configuration.
```

This confirms that the completed CI/CD deployment did not introduce drift into the Terraform-managed infrastructure.

## Final Validation Result

Task 09 successfully implemented and validated an automated CI/CD delivery process incorporating:

- Pull-request security and policy gates.
- Python unit testing.
- Terraform formatting and validation.
- AWS SAM validation and build.
- Checkov Policy-as-Code controls.
- Controlled negative security testing.
- GitHub Actions OIDC federation.
- Dedicated workload-scoped AWS deployment permissions.
- Automated AWS SAM deployment.
- Automated post-deployment health verification.
- Independent CloudFormation and HTTP validation.
- Terraform drift detection.

The controlled failures encountered during implementation provide additional security and engineering evidence. An undeclared application dependency was stopped before AWS authentication, while insufficient IAM authorization prevented the deployment operation until the specific required permission was identified and added.

This implementation demonstrates a DevSecOps delivery model in which testing, security validation, short-lived federated authentication, workload-scoped authorization, deployment automation, and operational verification are integrated into the software delivery lifecycle.

## Known Maintenance Item

GitHub Actions reported that Node.js 20 is deprecated for several referenced actions and that those actions are currently being forced to execute using Node.js 24.

The warning did not prevent successful deployment and is not an application failure. GitHub Actions dependencies should be periodically reviewed and upgraded to versions that natively support the current runner runtime.

## Security and Governance Value

This pipeline integrates Cloud Engineering, DevSecOps, Infrastructure as Code, and Cloud GRC practices.

Preventive controls include:

- Pull-request security gates.
- Policy-as-Code validation.
- Negative security testing.
- Restricted GitHub OIDC trust.
- Workload-scoped AWS IAM permissions.
- Separation of environment configuration from workflow logic.
- Feature-branch and pull-request deployment practices.

Detective and validation controls include:

- AWS caller identity verification.
- CloudFormation deployment status.
- Post-deployment application health validation.
- CloudWatch logging.
- Previously implemented operational monitoring and alarms.

The resulting delivery model demonstrates how automated engineering pipelines can enforce security and governance requirements while supporting repeatable cloud deployment.
