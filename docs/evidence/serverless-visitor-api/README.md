# Serverless Visitor Analytics API — Validation Evidence

## Overview

This implementation adds a serverless page-view analytics capability to the Secure Cloud Portfolio. The portfolio frontend invokes an Amazon API Gateway HTTP API, which routes visitor requests to AWS Lambda. The visitor Lambda atomically increments a counter stored in Amazon DynamoDB.

A separate health endpoint validates API availability without modifying visitor analytics data.

> The visitor counter represents page-view events and should not be interpreted as a count of verified unique visitors.

## Architecture

```text
Portfolio Browser
       |
       | HTTPS POST /visitor
       v
Amazon API Gateway
       |
       v
AWS Lambda
Visitor Counter
       |
       | dynamodb:UpdateItem
       v
Amazon DynamoDB
       |
       v
Atomic Page-View Count

GET /health
       |
       v
API Gateway
       |
       v
Health Lambda
       |
       +---- No DynamoDB access