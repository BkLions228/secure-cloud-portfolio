# Secure Cloud Portfolio
# Secure AWS Cloud Portfolio Platform

A production-style cloud portfolio built on AWS to demonstrate cloud engineering, DevSecOps, security governance, Infrastructure as Code, serverless application development, and CI/CD automation.

## Project Objectives

This project expands the traditional online resume into a secure, observable, and automated cloud platform.

The solution will include:

- A responsive cloud engineering portfolio
- Private Amazon S3 static website storage
- Amazon CloudFront content delivery
- AWS Certificate Manager TLS certificates
- Amazon Route 53 DNS
- Amazon API Gateway
- AWS Lambda
- Amazon DynamoDB
- Terraform infrastructure
- AWS SAM serverless resources
- GitHub Actions CI/CD
- GitHub OpenID Connect authentication
- CloudWatch monitoring and alerting
- Security and governance controls

## Architecture

The platform will use the following high-level request flow:

```text
User
  |
  >
Amazon Route 53
  |
  >
Amazon CloudFront
  |
  v
Private Amazon S3 Bucket
  |
  >
Frontend JavaScript
  |
  >
Amazon API Gateway
  |
  >
AWS Lambda
  |
  >
Amazon DynamoDB