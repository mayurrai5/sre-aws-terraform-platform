terraform {
  required_version = ">= 1.12.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.55"
    }
  }
}

provider "aws" {
  region  = "ap-south-1"
  profile = "sre-lab"
}

data "aws_caller_identity" "current" {}

# --------------------------------------------------
# Terraform state backend
# --------------------------------------------------

resource "aws_s3_bucket" "terraform_state" {
  bucket = "sre-aws-terraform-state-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "sre-aws-terraform-state"
    Environment = "bootstrap"
    ManagedBy   = "Terraform"
    Project     = "sre-aws-terraform-platform"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --------------------------------------------------
# GitHub Actions OIDC
# --------------------------------------------------

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = {
    Name      = "github-actions-oidc"
    ManagedBy = "Terraform"
    Project   = "sre-aws-terraform-platform"
  }
}

resource "aws_iam_role" "github_actions" {
  name = "sre-github-actions-terraform-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }

        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }

          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:mayurrai5@77747356/sre-aws-terraform-platform@1337022661:pull_request",
              "repo:mayurrai5@77747356/sre-aws-terraform-platform@1337022661:ref:refs/heads/main",
              "repo:mayurrai5@77747356/sre-aws-terraform-platform@1337022661:ref:refs/heads/ci/*"
            ]
          }
        }
      }
    ]
  })

  tags = {
    Name      = "sre-github-actions-terraform-role"
    ManagedBy = "Terraform"
    Project   = "sre-aws-terraform-platform"
  }
}
# --------------------------------------------------
# GitHub Actions Terraform permissions
# --------------------------------------------------

resource "aws_iam_role_policy" "github_actions_terraform" {
  name = "sre-github-actions-terraform-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [

      # Terraform remote state access
      {
        Sid    = "TerraformStateBucket"
        Effect = "Allow"

        Action = [
          "s3:ListBucket",
          "s3:GetBucketVersioning"
        ]

        Resource = aws_s3_bucket.terraform_state.arn
      },

      {
        Sid    = "TerraformStateObjects"
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]

        Resource = "${aws_s3_bucket.terraform_state.arn}/*"
      },

      # Read-only AWS access required for terraform plan
      {
        Sid    = "TerraformPlanReadAccess"
        Effect = "Allow"

        Action = [
          "ec2:Describe*",
          "iam:Get*",
          "iam:List*",
          "sts:GetCallerIdentity"
        ]

        Resource = "*"
      }
    ]
  })
}

# --------------------------------------------------
# Outputs
# --------------------------------------------------

output "terraform_state_bucket_name" {
  value = aws_s3_bucket.terraform_state.bucket
}

output "github_actions_role_arn" {
  description = "IAM role ARN assumed by GitHub Actions through OIDC"

  value = aws_iam_role.github_actions.arn
}