data "tls_certificate" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    data.tls_certificate.github_actions.certificates[0].sha1_fingerprint
  ]

  tags = {
    Name    = "github-actions-oidc"
    Purpose = "github-actions-federation"
  }
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    sid    = "AllowGitHubActionsOIDC"
    effect = "Allow"

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type = "Federated"

      identifiers = [
        aws_iam_openid_connect_provider.github_actions.arn
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
        "repo:${var.github_organization}/${var.github_repository}:ref:refs/heads/${var.github_branch}"
      ]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json

  tags = {
    Purpose = "secure-portfolio-frontend-deployment"
  }
}

data "aws_iam_policy_document" "deployment" {
  statement {
    sid    = "ListPortfolioBucket"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::${var.site_bucket_name}"
    ]
  }

  statement {
    sid    = "ManagePortfolioObjects"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "arn:aws:s3:::${var.site_bucket_name}/*"
    ]
  }

  statement {
    sid    = "InvalidatePortfolioCloudFrontCache"
    effect = "Allow"

    actions = [
      "cloudfront:CreateInvalidation"
    ]

    resources = [
      var.cloudfront_distribution_arn
    ]
  }
}

resource "aws_iam_policy" "deployment" {
  name        = "${var.role_name}-policy"
  description = "Least-privilege permissions for portfolio frontend deployments."
  policy      = data.aws_iam_policy_document.deployment.json
}

resource "aws_iam_role_policy_attachment" "deployment" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.deployment.arn
}