# Application Architecture

This diagram represents the currently deployed and validated development environment for the Secure AWS Cloud Portfolio Platform.

```mermaid
flowchart TB
    User([Internet User])

    subgraph Edge["Edge / Content Delivery"]
        CF[Amazon CloudFront<br/>HTTPS + Security Headers]
    end

    subgraph Frontend["Frontend"]
        S3[(Private Amazon S3<br/>Portfolio Origin)]
    end

    subgraph Serverless["Serverless Application"]
        API[Amazon API Gateway<br/>HTTP API]
        Health[AWS Lambda<br/>Health]
        Visitor[AWS Lambda<br/>Visitor Counter]
        DDB[(Amazon DynamoDB<br/>Page-View Counter)]
    end

    subgraph Operations["Monitoring & Operations"]
        CW[Amazon CloudWatch<br/>Logs, Metrics, Dashboard & Alarms]
        SNS[Amazon SNS<br/>Alert Routing]
        Logs[(Private S3<br/>CloudFront Access Logs)]
    end

    User -->|HTTPS| CF
    CF -->|Signed OAC Request| S3

    S3 -. Frontend JavaScript .-> API

    API -->|GET /health| Health
    API -->|POST /visitor| Visitor
    Visitor -->|Atomic UpdateItem| DDB

    CF -. Access Logs .-> Logs

    CF -. Metrics .-> CW
    API -. Access Logs / Metrics .-> CW
    Health -. Logs / Metrics .-> CW
    Visitor -. Logs / Metrics .-> CW
    DDB -. Metrics .-> CW

    CW -->|Alarm Actions| SNS
```

## Security Boundaries

The architecture applies several security boundaries:

- The portfolio S3 bucket is private.
- CloudFront accesses the origin through Origin Access Control (OAC).
- Direct public access to the portfolio S3 bucket is denied.
- Client traffic is redirected to HTTPS at CloudFront.
- API CORS is restricted to the portfolio origin.
- Lambda permissions are scoped to required application operations.
- DynamoDB encryption and point-in-time recovery are enabled.
- CloudFront access logs are stored in a dedicated private S3 logging bucket.
- CloudWatch provides centralized logs, metrics, alarms, and operational visibility.

## Request Paths

### Portfolio Delivery

```text
Internet
   ->
CloudFront
   ->
Signed OAC Request
   ->
Private S3
```

### Visitor Analytics

```text
Browser
   ->
POST /visitor
   ->
API Gateway
   ->
Visitor Lambda
   ->
DynamoDB
```

### Health Validation

```text
GET /health
   ->
API Gateway
   ->
Health Lambda
   ->
{"status":"healthy"}
```

The health route is intentionally separated from visitor analytics so operational and CI/CD validation does not modify the page-view counter.