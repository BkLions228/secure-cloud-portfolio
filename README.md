# Secure AWS Cloud Portfolio Platform

A production-style AWS cloud portfolio demonstrating cloud engineering, Infrastructure as Code, serverless development, DevSecOps, Cloud Security, Cloud GRC, Policy-as-Code, observability, and automated CI/CD.

The project extends a traditional cloud resume into a secure and operationally managed cloud platform. Infrastructure is provisioned through Terraform and AWS SAM, deployments are automated through GitHub Actions using OpenID Connect (OIDC), security controls are evaluated through Policy-as-Code, and operational health is monitored through Amazon CloudWatch.

> **Project Status:** Core development environment complete and production-validated.

## Project Overview

The Secure AWS Cloud Portfolio Platform demonstrates how a relatively small cloud application can incorporate engineering and governance practices normally associated with larger production environments.

The platform currently includes:

- A responsive cloud engineering portfolio
- Private Amazon S3 origin storage
- Amazon CloudFront content delivery
- CloudFront Origin Access Control (OAC)
- Serverless visitor analytics
- Amazon API Gateway
- AWS Lambda
- Amazon DynamoDB
- Terraform Infrastructure as Code
- AWS SAM serverless Infrastructure as Code
- GitHub Actions CI/CD
- GitHub OIDC federation with AWS
- Policy-as-Code using Checkov
- Controlled negative security testing
- Amazon CloudWatch dashboards, metrics, logs, and alarms
- Amazon SNS alert routing
- Automated post-deployment health validation
- Technical evidence and operational documentation

---

## Architecture

The platform separates the **application architecture** from the **engineering and deployment control plane**. This makes the runtime request path independent from the CI/CD and governance processes used to manage it.

### Application Architecture

```text
                         Internet
                            |
                            v
                    Amazon CloudFront
                            |
                      HTTPS + OAC
                            |
                            v
                    Private Amazon S3
                      Portfolio Site
                            |
                    Frontend JavaScript
                            |
                            v
                 Amazon API Gateway HTTP API
                            |
                  +---------+---------+
                  |                   |
                  v                   v
            Health Lambda       Visitor Lambda
                                      |
                                      v
                               Amazon DynamoDB
```

The frontend is delivered through Amazon CloudFront while the S3 origin remains private. CloudFront Origin Access Control allows CloudFront to retrieve portfolio objects without exposing the S3 bucket directly to the internet.

Frontend JavaScript communicates with a serverless HTTP API. A dedicated health Lambda provides non-mutating service validation, while the visitor Lambda performs an atomic DynamoDB update for the portfolio page-view counter.

### Engineering and CI/CD Architecture

```text
Developer
    |
    v
Feature Branch
    |
    v
Pull Request
    |
    +--> Python Unit Tests
    +--> Terraform Format / Validation
    +--> AWS SAM Validation
    +--> Checkov Policy-as-Code
    +--> Negative Security Tests
    |
    v
Merge to main
    |
    +-----------------------------+
    |                             |
    v                             v
Frontend Workflow           Backend Workflow
    |                             |
    v                             v
GitHub OIDC                 GitHub OIDC
    |                             |
    v                             v
AWS STS                     AWS STS
    |                             |
    v                             v
Private S3 +                AWS SAM /
CloudFront                  CloudFormation
                                  |
                                  v
                          Post-Deployment
                          Health Validation
```

GitHub Actions does not require long-lived AWS access keys. Deployment workflows request short-lived AWS credentials through GitHub OIDC federation and AWS STS.

The frontend and backend use separate deployment IAM roles so permissions can be scoped according to each workload.

---

### Detailed Architecture Diagrams

Additional source-controlled architecture diagrams are available in the repository:

- [Application Architecture](docs/diagrams/application-architecture.md) — runtime request flow, serverless application, monitoring, and logging architecture.
- [DevSecOps and CI/CD Architecture](docs/diagrams/cicd-security-architecture.md) — pull-request validation, Policy-as-Code, GitHub OIDC, AWS deployment roles, and automated delivery architecture.

The diagrams are maintained as Mermaid source in Markdown so architectural changes can be reviewed and version-controlled alongside the platform.

## Live Development Environment

**Portfolio**

```text
https://d14dbqwc0rqzs.cloudfront.net
```

**Serverless API**

```text
https://sqk3sg1oj5.execute-api.us-east-1.amazonaws.com/dev
```

**Health Endpoint**

```text
https://sqk3sg1oj5.execute-api.us-east-1.amazonaws.com/dev/health
```

The health endpoint provides a non-mutating method for validating the deployed backend without incrementing the visitor counter.

---

## Technology Stack

| Category | Technology |
|---|---|
| Cloud Provider | AWS |
| Infrastructure as Code | Terraform |
| Serverless IaC | AWS SAM / CloudFormation |
| Frontend | HTML, CSS, JavaScript |
| CDN | Amazon CloudFront |
| Object Storage | Amazon S3 |
| API | Amazon API Gateway HTTP API |
| Compute | AWS Lambda |
| Database | Amazon DynamoDB |
| Monitoring | Amazon CloudWatch |
| Alert Routing | Amazon SNS |
| CI/CD | GitHub Actions |
| AWS Authentication | GitHub OIDC / AWS STS |
| Policy-as-Code | Checkov |
| Testing | pytest |
| Version Control | Git / GitHub |

---

## Security Architecture

Security controls are integrated throughout the platform rather than added only at deployment time.

### S3 and CloudFront Security

The frontend architecture uses a private S3 origin behind CloudFront.

Implemented controls include:

- S3 Block Public Access
- `BucketOwnerEnforced` ownership controls for the portfolio bucket
- Server-side encryption using SSE-S3
- S3 versioning
- Lifecycle management
- CloudFront Origin Access Control (OAC)
- SigV4-signed CloudFront origin requests
- Direct public S3 access denied
- HTTP-to-HTTPS redirection at CloudFront
- CloudFront security response headers
- Dedicated CloudFront access-log bucket
- Access-log lifecycle management
- Explicit denial of insecure S3 transport

The resulting request model is:

```text
Internet
   |
   v
CloudFront
   |
   | Signed OAC Request
   v
Private S3 Origin

Direct Internet -> S3 = Denied
```

This allows the portfolio to remain publicly accessible through CloudFront without turning the underlying S3 bucket into a public website.

### Identity and CI/CD Security

GitHub Actions authenticates to AWS through OpenID Connect rather than stored AWS access keys.

```text
GitHub Actions
      |
      | OIDC Token
      v
    AWS STS
      |
      | Short-Lived Credentials
      v
Deployment IAM Role
```

The implementation includes:

- No long-lived AWS deployment access keys
- Separate frontend and backend deployment IAM roles
- Repository-restricted OIDC trust
- Main-branch-restricted deployment trust
- Immutable GitHub organization/user and repository identifiers in the trust relationship
- Workload-scoped deployment permissions
- Terraform-managed IAM configuration
- GitHub pull-request workflow
- No direct pushes to `main`

The backend deployment role is intentionally described as **workload-scoped** rather than perfectly least privilege. AWS SAM requires access to generated and managed deployment resources, and some permissions therefore use bounded resource patterns.

### Serverless Security

The serverless application includes:

- Restricted CORS configuration
- DynamoDB server-side encryption
- DynamoDB point-in-time recovery
- Application IAM permissions limited to required DynamoDB operations
- API Gateway access logging
- Structured API log records
- AWS X-Ray tracing for Lambda
- Operational log retention
- Non-mutating health validation

The visitor Lambda is granted the DynamoDB operation required to update the visitor counter rather than broad DynamoDB administrative permissions.

---

## Infrastructure as Code

The platform uses two complementary Infrastructure as Code technologies.

```text
Terraform
   |
   +--> Static Site Infrastructure
   +--> CloudFront
   +--> GitHub OIDC
   +--> Deployment IAM
   +--> Monitoring
   +--> Alerting

AWS SAM
   |
   +--> API Gateway
   +--> Lambda
   +--> DynamoDB
   +--> Serverless IAM
   +--> API Logging
```

### Terraform

Terraform manages persistent platform infrastructure and security controls.

Current reusable modules are:

```text
infrastructure/modules/
├── github-backend-deploy/
├── github-oidc/
├── monitoring/
└── static-site/
```

The modules manage resources including:

- Private S3 portfolio storage
- CloudFront distribution
- CloudFront Origin Access Control
- CloudFront access logging
- GitHub Actions OIDC provider
- Frontend deployment IAM role
- Backend deployment IAM role
- CloudWatch dashboard
- CloudWatch alarms
- CloudWatch metric filters
- SNS monitoring topic

Environment-specific composition is maintained under:

```text
infrastructure/environments/
├── dev/
└── prod/
```

The development environment is currently the validated deployed environment. The presence of a production directory does not imply that a production AWS environment has been deployed.

### Remote Terraform State

Terraform state is stored remotely in Amazon S3 rather than only on a developer workstation.

The state backend includes:

- S3 versioning
- Server-side encryption
- S3 Block Public Access
- Ownership controls
- Lifecycle management
- Protection against accidental Terraform destruction of the state bucket

The development state is separated through its own backend key.

This provides a foundation for controlled infrastructure collaboration and future environment separation.

### AWS SAM

AWS SAM manages the serverless application.

```text
backend/
├── src/
│   ├── health/
│   └── visitor_counter/
├── tests/
├── requirements.txt
├── requirements-dev.txt
└── template.yaml
```

The SAM template defines:

- Amazon API Gateway HTTP API
- Health Lambda
- Visitor Counter Lambda
- DynamoDB visitor table
- API access logging
- Lambda environment configuration
- Application IAM permissions
- Serverless resource outputs

Separating the serverless application from the persistent Terraform-managed platform allows each tool to be used for the area where it provides the clearest operational workflow.

---

## Serverless Visitor Analytics

The portfolio includes a serverless page-view analytics service implemented with API Gateway, Lambda, and DynamoDB.

### Visitor Request Flow

```text
Portfolio Browser
       |
       | POST /visitor
       v
API Gateway HTTP API
       |
       v
Visitor Counter Lambda
       |
       | Atomic UpdateItem
       v
Amazon DynamoDB
```

The DynamoDB table stores the portfolio counter using:

```text
counter_id = portfolio
```

The visitor Lambda performs an atomic DynamoDB update instead of a separate read-modify-write sequence.

This reduces the risk of lost updates when multiple requests occur concurrently.

The counter represents **portfolio page views** rather than cryptographically verified unique visitors.

### Health Endpoint

The application also provides:

```text
GET /health
```

A successful request returns:

```json
{
  "status": "healthy"
}
```

The health Lambda does not update DynamoDB.

This separation provides a non-mutating endpoint for:

- CI/CD post-deployment validation
- Operational health checks
- Troubleshooting
- Service verification without altering analytics data

### Backend Testing

Backend tests are maintained under:

```text
backend/tests/
├── test_health.py
└── test_visitor_counter.py
```

The tests validate health-handler behavior and visitor-counter behavior before application deployment.

---

## Automated CI/CD

The project uses three GitHub Actions workflows:

```text
.github/workflows/
├── deploy-backend.yml
├── deploy-frontend.yml
└── policy-as-code.yml
```

Together, these workflows separate security validation from application deployment.

### Pull Request Validation

Infrastructure and backend changes are evaluated before merge through the Policy-as-Code workflow.

```text
Feature Branch
      |
      v
Pull Request
      |
      +--> Python Unit Tests
      +--> Terraform fmt
      +--> Terraform validate
      +--> AWS SAM validate
      +--> Checkov
      +--> Negative Policy Tests
      |
      v
Merge Decision
```

This creates a preventive control layer before changes reach `main`.

### Frontend Deployment

The frontend deployment workflow uses GitHub OIDC to assume a dedicated AWS deployment role.

The workflow performs:

1. Repository checkout
2. GitHub OIDC authentication
3. AWS STS role assumption
4. AWS identity verification
5. S3 synchronization
6. Cache-control handling
7. CloudFront invalidation

Static assets receive cache-friendly settings while the main HTML document is deployed with more restrictive cache behavior.

### Backend Deployment

The backend deployment workflow performs:

1. Repository checkout
2. Python 3.10 setup
3. Development dependency installation
4. Backend unit testing
5. Isolated AWS SAM CLI installation
6. SAM template validation
7. SAM application build
8. GitHub OIDC authentication
9. AWS identity verification
10. SAM deployment
11. CloudFormation output discovery
12. Post-deployment health validation

The deployment pipeline requires the health endpoint to return HTTP `200` and:

```json
{
  "status": "healthy"
}
```

before the deployment validation stage is considered successful.

### Validated Deployment

The production-validation run for the development environment was:

```text
GitHub Actions Run: 35677110833
Result: Success
```

The deployed CloudFormation stack subsequently reported:

```text
UPDATE_COMPLETE
```

Independent validation of the health endpoint returned:

```text
HTTP/1.1 200 OK

{"status": "healthy"}
```

A final Terraform plan reported:

```text
No changes. Your infrastructure matches the configuration.
```

This provides independent confirmation that the automated deployment completed successfully without introducing Terraform-detected infrastructure drift.

---

## Policy-as-Code

Security controls are implemented as executable CI checks using Checkov.

The policy layer is maintained under:

```text
policy/
├── README.md
├── requirements.txt
└── tests/
```

The CI policy baseline evaluates controls covering areas such as:

- S3 public-access prevention
- S3 encryption
- S3 versioning
- CloudFront HTTPS enforcement
- Private S3 origin architecture
- Dangerous IAM wildcard restrictions
- GitHub OIDC trust restrictions
- DynamoDB encryption
- DynamoDB point-in-time recovery
- API access logging
- CORS restrictions
- Governance tagging

### Curated Terraform Security Gate

The validated Task 09 Terraform security gate produced:

```text
37 passed
0 failed
0 skipped
```

### Curated SAM Security Gate

The validated SAM security gate produced:

```text
7 passed
0 failed
0 skipped
```

These results represent the project's explicitly enforced CI control baseline.

They do **not** mean that every possible Checkov recommendation is implemented. Broader security assessments can identify additional hardening opportunities that are intentionally evaluated separately from the blocking CI baseline.

### Negative Security Testing

The project also includes deliberately insecure test fixtures.

```text
policy/tests/fixtures/fail/
├── cloudformation/
└── terraform/
```

These fixtures verify that security controls fail when prohibited configurations are introduced.

The validated negative-test suite produced expected failures for insecure Terraform and SAM configurations and returned:

```text
ALL NEGATIVE POLICY TESTS PASSED
```

This approach tests not only whether compliant infrastructure passes, but whether intentionally noncompliant infrastructure is actually rejected.

### Policy Exception Management

Not every desired control can always be implemented immediately.

For example, Lambda reserved concurrency was evaluated during the security-hardening phase but could not be safely enabled because of the available account concurrency quota.

Rather than representing the control as implemented, the limitation was documented as an exception.

This demonstrates an important governance principle:

```text
Identify Control
      |
      v
Evaluate Feasibility
      |
      +--> Implement -> Validate -> Monitor
      |
      +--> Constraint -> Document Exception
                           |
                           v
                       Reassess Later
```

Policy-as-Code therefore functions as both an engineering control and a Cloud GRC evidence mechanism.

---

## Monitoring and Observability

Amazon CloudWatch provides centralized operational visibility across the frontend, API, compute, and data layers of the platform.

### Operations Dashboard

The Terraform-managed CloudWatch dashboard is:

```text
secure-cloud-portfolio-dev-operations
```

The dashboard provides a centralized view of operational metrics associated with the portfolio platform.

### CloudWatch Alarms

The development environment currently includes ten Terraform-managed CloudWatch alarms:

| # | Monitored Condition |
|---:|---|
| 1 | CloudFront 5xx error rate |
| 2 | API Gateway 5xx responses |
| 3 | API Gateway latency |
| 4 | API log-derived server errors |
| 5 | Health Lambda errors |
| 6 | Health Lambda throttles |
| 7 | Visitor Lambda errors |
| 8 | Visitor Lambda throttles |
| 9 | Visitor Lambda duration |
| 10 | DynamoDB system errors |

The monitoring design covers multiple layers of the request path:

```text
CloudFront
    |
    v
API Gateway
    |
    v
Lambda
    |
    v
DynamoDB
```

This allows failures to be observed closer to the layer where they occur rather than relying on a single application-level health signal.

### Log-Derived Metrics

API Gateway access logs are written to CloudWatch Logs using structured records.

A Terraform-managed metric filter evaluates the API logs for server-side HTTP responses:

```text
{ $.status >= 500 }
```

Matching events publish the custom metric:

```text
Namespace: SecureCloudPortfolio/dev
Metric:    ApiServerErrors
```

A CloudWatch alarm monitors this metric.

The metric-filter logic was tested against synthetic status values to verify that server errors such as `500`, `502`, and `503` matched while non-server responses such as `200` and `404` did not.

### CloudFront Access Logging

CloudFront standard access logging is enabled and delivers log objects to a dedicated S3 logging bucket.

Observed log delivery confirmed that CloudFront was physically writing compressed access-log objects under the configured prefix.

The logging bucket includes:

- S3 Block Public Access
- SSE-S3 encryption
- Versioning
- Lifecycle management
- Dedicated operational logging purpose

This closed the Policy-as-Code evidence requirement for CloudFront access logging.

### Alert Routing

Amazon SNS provides the notification-routing layer for CloudWatch alarms.

A controlled CloudWatch alarm-state test was used to validate alarm action routing behavior, after which the alarm was returned to its normal state.

The project does not treat manual alarm-state manipulation as proof that a real metric threshold occurred. It validates the configured alarm action path rather than the underlying production failure condition.

### Missing Data Behavior

Where appropriate, alarms use:

```text
treat_missing_data = "notBreaching"
```

This reduces unnecessary alarm transitions when a low-traffic portfolio does not continuously emit a particular metric.

---

## Consolidated Validation Results

The platform has been validated across application, infrastructure, security, deployment, and operational layers.

| Validation Area | Result |
|---|---|
| CloudFront portfolio delivery | HTTP 200 |
| Direct S3 access | HTTP 403 |
| Private S3 origin through OAC | Validated |
| Backend unit tests | Passed |
| Health API | HTTP 200 |
| Health response | `{"status":"healthy"}` |
| Visitor API | Operational |
| DynamoDB page-view counter | Operational |
| AWS SAM validation | Passed |
| Terraform validation | Passed |
| Curated Terraform Checkov gate | 37 passed / 0 failed / 0 skipped |
| Curated SAM Checkov gate | 7 passed / 0 failed / 0 skipped |
| Negative security tests | Passed |
| GitHub OIDC authentication | Passed |
| Automated frontend deployment | Passed |
| Automated backend deployment | Passed |
| CloudFormation backend stack | `UPDATE_COMPLETE` |
| CloudFront access-log delivery | Verified |
| CloudWatch monitoring resources | Deployed |
| API server-error metric filter | Validated |
| Terraform final plan | No changes / zero drift |
| Public evidence account-ID disclosure check | Passed |

Validation is intentionally described at the level actually tested. A passing curated Policy-as-Code gate, for example, does not imply that every possible infrastructure hardening recommendation has been implemented.

---

## Engineering Failures and Lessons Learned

The project preserves controlled failures because troubleshooting and remediation are important parts of production cloud engineering.

### CI Dependency Failure

The first automated backend deployment attempt failed during unit testing before AWS authentication.

The clean GitHub Actions runner reported:

```text
ModuleNotFoundError: No module named 'boto3'
```

The local development environment already contained `boto3`, which had hidden the undeclared CI dependency.

The remediation added the dependency explicitly to:

```text
backend/requirements-dev.txt
```

The corrected change was reviewed and merged through a pull request.

**Engineering lesson:** clean CI environments reveal undeclared dependencies that may remain hidden on long-lived developer workstations.

More importantly, the pipeline failed before obtaining AWS deployment credentials or changing cloud resources.

### Least-Privilege IAM Failure

The second backend deployment attempt progressed substantially further:

```text
Unit Tests
    |
    v
SAM Validation
    |
    v
SAM Build
    |
    v
GitHub OIDC
    |
    v
AWS Identity Verification
    |
    v
SAM Artifact Upload
    |
    v
CloudFormation Change Set
    |
    X  Access Denied
```

AWS denied:

```text
cloudformation:CreateChangeSet
```

for the AWS-managed SAM transform resource.

Instead of broadening CloudFormation authorization to unrestricted resources, the deployment policy was updated with the specific required resource:

```text
arn:aws:cloudformation:us-east-1:aws:transform/Serverless-2016-10-31
```

The IAM change was then validated through:

- Terraform validation
- Terraform plan review
- Curated Checkov scanning
- Explicit unrestricted-resource checking
- Terraform apply
- AWS-side IAM policy verification
- Post-apply Terraform drift validation
- Pull-request Policy-as-Code validation

**Engineering lesson:** restrictive IAM can expose missing permissions during real deployment while still allowing the remediation to remain narrowly scoped.

### Successful End-to-End Deployment

Following both remediations, the third backend deployment completed successfully.

```text
Test
  |
  v
Validate
  |
  v
Build
  |
  v
OIDC Authenticate
  |
  v
Deploy
  |
  v
Discover Endpoint
  |
  v
Health Validate
  |
  v
SUCCESS
```

GitHub Actions run:

```text
35677110833
```

completed the automated delivery lifecycle successfully.

Independent AWS validation subsequently confirmed:

```text
CloudFormation: UPDATE_COMPLETE
Health API:     HTTP 200
Terraform:      No changes
```

**Engineering lesson:** a green CI/CD run is stronger evidence when it is supplemented with independent cloud-state, application-health, and infrastructure-drift validation.

---

## Operational Design Principles

Several principles guided implementation decisions throughout the project.

### Fail Before Deployment

Testing and policy validation occur before AWS deployment whenever possible.

```text
Detect Early
    >
Prevent Deployment
    >
Remediate
    >
Revalidate
```

### Short-Lived Authentication

GitHub Actions uses OIDC and AWS STS rather than persistent deployment credentials.

### Separate Deployment Roles

Frontend and backend deployment responsibilities use separate IAM roles instead of one general-purpose CI/CD role.

### Infrastructure Drift Awareness

Terraform plan is used after significant infrastructure changes to verify that the declared configuration matches the managed AWS environment.

### Security as Executable Controls

Security requirements are represented through:

```text
Terraform
    +
SAM
    +
Checkov
    +
Negative Tests
    +
GitHub Actions
```

rather than relying only on written security documentation.

### Evidence-Based Validation

The project preserves implementation evidence for major controls and deployment milestones so security and operational claims can be traced back to validation activity.

---

## Key Engineering Decisions

The project documents not only what was deployed, but why specific architectural and security decisions were made.

### Private S3 Instead of Public Website Hosting

The portfolio S3 bucket is not configured as a public S3 website.

Instead:

```text
Internet
   |
   v
CloudFront
   |
   | Origin Access Control
   v
Private S3
```

This keeps the origin private while allowing CloudFront to provide public content delivery, HTTPS enforcement, caching, and security response headers.

### OIDC Instead of Stored AWS Credentials

GitHub Actions authenticates through OIDC federation and AWS STS.

This avoids maintaining long-lived AWS access keys inside GitHub and allows the AWS trust policy to restrict which repository and branch may request deployment credentials.

### Separate Frontend and Backend Deployment Roles

The frontend and backend have different AWS deployment requirements.

Rather than using one general-purpose CI/CD role, the platform separates these responsibilities into dedicated IAM roles.

This reduces unnecessary permission sharing between deployment workflows and makes IAM policies easier to reason about and audit.

### Terraform and AWS SAM Together

Terraform manages persistent platform infrastructure such as:

```text
S3
CloudFront
GitHub OIDC
IAM
CloudWatch
SNS
```

AWS SAM manages the serverless application:

```text
API Gateway
Lambda
DynamoDB
Application IAM
API Logging
```

This division allows Terraform to manage the broader cloud platform while SAM provides a deployment workflow optimized for the serverless application.

### Dedicated Health Endpoint

The application separates health validation from visitor analytics.

```text
GET /health
    |
    +--> Validate Service

POST /visitor
    |
    +--> Update Page-View Counter
```

CI/CD can therefore validate the deployed application without changing analytics data.

### Curated Blocking Security Baseline

The CI pipeline uses a curated set of Checkov controls as the blocking security baseline.

Broader security scans are treated as additional assessment data rather than automatically blocking every deployment.

This distinction makes it possible to:

- Enforce required controls
- Track additional hardening opportunities
- Document justified exceptions
- Avoid representing every scanner recommendation as an equally critical deployment requirement

---

## Repository Structure

```text
secure-cloud-portfolio/
├── .github/
│   └── workflows/
│       ├── deploy-backend.yml
│       ├── deploy-frontend.yml
│       └── policy-as-code.yml
│
├── backend/
│   ├── src/
│   │   ├── health/
│   │   └── visitor_counter/
│   ├── tests/
│   ├── requirements.txt
│   ├── requirements-dev.txt
│   └── template.yaml
│
├── docs/
│   ├── evidence/
│   │   ├── automated-cicd/
│   │   ├── monitoring-observability/
│   │   ├── policy-as-code/
│   │   └── serverless-visitor-api/
│   ├── architecture.md
│   ├── cost-estimate.md
│   ├── deployment-guide.md
│   ├── security-controls.md
│   └── threat-model.md
│
├── frontend/
│   ├── assets/
│   ├── css/
│   ├── js/
│   └── index.html
│
├── infrastructure/
│   ├── bootstrap/
│   ├── environments/
│   │   ├── dev/
│   │   └── prod/
│   └── modules/
│       ├── github-backend-deploy/
│       ├── github-oidc/
│       ├── monitoring/
│       └── static-site/
│
├── policy/
│   ├── tests/
│   ├── README.md
│   └── requirements.txt
│
├── scripts/
├── .gitignore
├── LICENSE
├── Makefile
└── README.md
```

The repository separates application code, infrastructure, security policy, automation, and evidence so that each area can evolve independently while remaining part of one platform.

---

## Documentation and Evidence

Detailed evidence is maintained under:

```text
docs/evidence/
```

### Serverless Visitor API

```text
docs/evidence/serverless-visitor-api/README.md
```

Documents the API Gateway, Lambda, DynamoDB, testing, CORS, logging, and runtime validation performed for the serverless application.

### Policy-as-Code

```text
docs/evidence/policy-as-code/README.md
```

Documents the security-control baseline, Checkov validation, negative testing, control exceptions, and CI security-gate implementation.

### Monitoring and Observability

```text
docs/evidence/monitoring-observability/README.md
```

Documents the CloudWatch dashboard, alarms, log-derived metric, CloudFront access logging, alert routing, and operational validation.

### Automated CI/CD

```text
docs/evidence/automated-cicd/README.md
```

Documents the frontend and backend deployment architecture, GitHub OIDC configuration, CI/CD failures and remediations, successful automated deployment, independent health validation, and Terraform drift verification.

### Supporting Documentation

Additional project documentation includes:

- `docs/architecture.md`
- `docs/cost-estimate.md`
- `docs/deployment-guide.md`
- `docs/security-controls.md`
- `docs/threat-model.md`

Together, these documents provide a deeper technical record than the root README alone.

---

## Skills Demonstrated

### AWS Cloud Engineering

- Amazon S3
- Amazon CloudFront
- CloudFront Origin Access Control
- Amazon API Gateway
- AWS Lambda
- Amazon DynamoDB
- Amazon CloudWatch
- Amazon SNS
- AWS IAM
- AWS STS

### Infrastructure as Code

- Terraform
- Reusable Terraform modules
- Remote Terraform state
- AWS SAM
- AWS CloudFormation
- Infrastructure drift validation

### DevOps and DevSecOps

- Git
- GitHub
- GitHub Actions
- CI/CD pipeline design
- Feature-branch workflows
- Pull-request validation
- Automated testing
- Automated deployment
- Post-deployment verification
- GitHub OIDC federation

### Cloud Security

- Least-privilege design
- Workload-scoped IAM
- Private cloud storage
- HTTPS enforcement
- Security headers
- Encryption
- Logging
- Restricted CORS
- Short-lived cloud credentials

### Cloud Governance and GRC

- Policy-as-Code
- Checkov
- Preventive security controls
- Negative security testing
- Security exception documentation
- Governance tagging
- Evidence collection
- Control validation
- Monitoring and alerting
- Infrastructure drift detection

### Serverless Engineering

- Python Lambda development
- API Gateway HTTP APIs
- DynamoDB atomic updates
- pytest
- AWS SAM build and deployment
- Health-check design

### Operational Engineering

- CloudWatch dashboards
- CloudWatch alarms
- Structured API logging
- Log-derived metrics
- SNS alert routing
- Troubleshooting
- Deployment validation
- Failure analysis and remediation

---

## Future Enhancements

The following capabilities are intentionally documented as future enhancements rather than currently deployed components.

### Custom Domain and DNS

Potential additions:

- Amazon Route 53
- AWS Certificate Manager
- Custom portfolio domain
- Automated DNS configuration

### Edge Security

Potential additions:

- AWS WAF
- Managed WAF rule groups
- Rate-based rules
- Additional CloudFront protections

### Multi-Environment Architecture

The repository contains an environment structure capable of supporting additional environments, but only the development environment is currently documented as deployed and validated.

A future implementation could introduce:

```text
Development
    |
    v
Staging
    |
    v
Production
```

with separate state, deployment roles, configuration, and approval controls.

### Multi-Account AWS Architecture

A future enterprise version could separate workloads across AWS accounts, for example:

```text
Management
    |
    +--> Security
    |
    +--> Logging
    |
    +--> Development
    |
    +--> Production
```

### Additional Security Services

Potential additions include:

- AWS Config
- AWS CloudTrail enhancements
- Amazon GuardDuty
- AWS Security Hub
- Amazon Inspector
- AWS KMS customer-managed keys

### FinOps

Future cost-governance enhancements could include:

- AWS Budgets
- Cost anomaly detection
- Cost allocation tagging
- Service-level cost dashboards
- Environment cost comparisons

### Containers

A future project phase could introduce containerized workloads using services such as Amazon ECS or Amazon EKS without replacing the serverless architecture demonstrated here.

These enhancements are intentionally separated from the current implementation so the portfolio does not represent planned capabilities as already deployed.

---

## Project Outcome

The Secure AWS Cloud Portfolio Platform evolved from a static portfolio into a secure, observable, policy-controlled, and automatically deployed cloud application.

The final development environment combines:

```text
Cloud Engineering
       +
Infrastructure as Code
       +
Serverless Architecture
       +
DevOps
       +
DevSecOps
       +
Policy-as-Code
       +
Cloud Security
       +
Cloud GRC
       +
Monitoring and Observability
```

The project demonstrates that cloud engineering is not only about provisioning resources.

A production-oriented cloud platform also requires:

- Repeatable infrastructure
- Controlled identity and access
- Automated testing
- Preventive security controls
- Deployment automation
- Monitoring
- Troubleshooting
- Evidence collection
- Drift awareness
- Technical documentation

The result is a portfolio platform that demonstrates the complete lifecycle from architecture and infrastructure provisioning through security validation, automated deployment, operational monitoring, and governance.