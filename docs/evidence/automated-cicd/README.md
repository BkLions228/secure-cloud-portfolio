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

## Current Deployment Validation Status

The AWS IAM infrastructure required by the GitHub backend deployment pipeline has been successfully deployed.

Terraform reports:

    No changes. Your infrastructure matches the configuration.

The GitHub Actions backend deployment workflow has been locally validated but is not yet considered production-validated.

Final CI/CD deployment validation still requires:

1. Open the Task 09 pull request.
2. Confirm the GitHub Policy-as-Code workflow passes.
3. Merge the approved pull request into `main`.
4. Confirm the backend deployment workflow starts from `main`.
5. Confirm GitHub successfully assumes the AWS role through OIDC.
6. Confirm the SAM/CloudFormation deployment succeeds.
7. Confirm the post-deployment health check returns HTTP 200 and a healthy status.
8. Record the successful GitHub Actions run as final deployment evidence.

The final workflow run information will be added after successful execution.

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
