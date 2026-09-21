data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  stack_name = "${var.project_name}-${var.environment}-api"

  github_subject = "repo:${var.github_organization}@${var.github_organization_id}/${var.github_repository}@${var.github_repository_id}:ref:refs/heads/${var.github_branch}"
}

#
# GitHub Actions OIDC Trust
#

data "aws_iam_policy_document" "assume_role" {
  statement {
    sid    = "AllowGitHubActionsOIDC"
    effect = "Allow"

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type = "Federated"

      identifiers = [
        var.github_oidc_provider_arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"

      values = [
        "sts.amazonaws.com"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"

      values = [
        local.github_subject
      ]
    }
  }
}

resource "aws_iam_role" "github_backend_deploy" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Purpose     = "github-actions-backend-deployment"
  }
}

#
# Backend Deployment Permissions
#

data "aws_iam_policy_document" "github_backend_deploy" {

  #
  # SAM artifact bucket
  #

  statement {
    sid    = "ListSamArtifactBucket"
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::aws-sam-cli-managed-default-samclisourcebucket-*"
    ]
  }

  statement {
    sid    = "ManageSamArtifacts"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]

    resources = [
      "arn:aws:s3:::aws-sam-cli-managed-default-samclisourcebucket-*/*"
    ]
  }

  #
  # CloudFormation deployment
  #

  statement {
    sid    = "ManageBackendCloudFormationStack"
    effect = "Allow"

    actions = [
      "cloudformation:CreateChangeSet",
      "cloudformation:DeleteChangeSet",
      "cloudformation:DescribeChangeSet",
      "cloudformation:DescribeStackEvents",
      "cloudformation:DescribeStackResource",
      "cloudformation:DescribeStackResources",
      "cloudformation:DescribeStacks",
      "cloudformation:ExecuteChangeSet",
      "cloudformation:GetTemplate",
      "cloudformation:GetTemplateSummary",
      "cloudformation:ListStackResources",
      "cloudformation:UpdateStack"
    ]

    resources = [
      "arn:aws:cloudformation:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:stack/${local.stack_name}/*"
    ]
  }
  #
  # AWS SAM transform
  #

  statement {
    sid    = "AllowSamTransformChangeSet"
    effect = "Allow"

    actions = [
      "cloudformation:CreateChangeSet"
    ]

    resources = [
      "arn:aws:cloudformation:${data.aws_region.current.region}:aws:transform/Serverless-2016-10-31"
    ]
  }
  #
  # Lambda functions
  #

  statement {
    sid    = "ManagePortfolioLambdaFunctions"
    effect = "Allow"

    actions = [
      "lambda:AddPermission",
      "lambda:CreateFunction",
      "lambda:DeleteFunction",
      "lambda:GetFunction",
      "lambda:GetFunctionConfiguration",
      "lambda:ListTags",
      "lambda:RemovePermission",
      "lambda:TagResource",
      "lambda:UntagResource",
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration"
    ]

    resources = [
      "arn:aws:lambda:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-${var.environment}-*"
    ]
  }

  #
  # SAM-generated Lambda execution roles
  #

  statement {
    sid    = "ManagePortfolioLambdaRoles"
    effect = "Allow"

    actions = [
      "iam:AttachRolePolicy",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:DeleteRolePolicy",
      "iam:DetachRolePolicy",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:PassRole",
      "iam:PutRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy"
    ]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.stack_name}-*",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-de-*"
    ]
  }

  #
  # API Gateway HTTP API
  #

  statement {
    sid    = "ManagePortfolioHttpApi"
    effect = "Allow"

    actions = [
      "apigateway:DELETE",
      "apigateway:GET",
      "apigateway:PATCH",
      "apigateway:POST",
      "apigateway:PUT"
    ]

    resources = [
      "arn:aws:apigateway:${data.aws_region.current.region}::/apis/*"
    ]
  }

  #
  # DynamoDB visitor table
  #

  statement {
    sid    = "ManageVisitorTable"
    effect = "Allow"

    actions = [
      "dynamodb:CreateTable",
      "dynamodb:DeleteTable",
      "dynamodb:DescribeContinuousBackups",
      "dynamodb:DescribeTable",
      "dynamodb:DescribeTimeToLive",
      "dynamodb:ListTagsOfResource",
      "dynamodb:TagResource",
      "dynamodb:UntagResource",
      "dynamodb:UpdateContinuousBackups",
      "dynamodb:UpdateTable"
    ]

    resources = [
      "arn:aws:dynamodb:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:table/${var.project_name}-${var.environment}-visitors"
    ]
  }

  #
  # API access log group
  #

  statement {
    sid    = "ManageApiAccessLogGroup"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:DeleteLogGroup",
      "logs:DescribeLogGroups",
      "logs:ListTagsForResource",
      "logs:PutRetentionPolicy",
      "logs:TagResource",
      "logs:UntagResource"
    ]

    resources = [
      "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/apigateway/${var.project_name}-${var.environment}-visitor-api:*"
    ]
  }
}

resource "aws_iam_policy" "github_backend_deploy" {
  name = "${var.role_name}-policy"

  description = (
    "Least-privilege permissions for GitHub Actions SAM backend deployments."
  )

  policy = data.aws_iam_policy_document.github_backend_deploy.json
}

resource "aws_iam_role_policy_attachment" "github_backend_deploy" {
  role       = aws_iam_role.github_backend_deploy.name
  policy_arn = aws_iam_policy.github_backend_deploy.arn
}
