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
# KMS key for Terraform state encryption
# --------------------------------------------------

resource "aws_kms_key" "terraform_state" {
  description             = "KMS key for Terraform state bucket encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "sre-terraform-state-kms-key"
    Environment = "bootstrap"
    ManagedBy   = "Terraform"
    Project     = "sre-aws-terraform-platform"
  }
}

resource "aws_kms_alias" "terraform_state" {
  name          = "alias/sre-terraform-state"
  target_key_id = aws_kms_key.terraform_state.key_id
}

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
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.terraform_state.arn
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

      # ----------------------------------------------
      # Terraform remote state bucket access
      # ----------------------------------------------

      {
        Sid    = "TerraformStateBucket"
        Effect = "Allow"

        Action = [
          "s3:ListBucket",
          "s3:GetBucketVersioning"
        ]

        Resource = aws_s3_bucket.terraform_state.arn
      },

      # ----------------------------------------------
      # Terraform remote state object access
      # ----------------------------------------------

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

      # ----------------------------------------------
      # KMS permissions for encrypted Terraform state
      # ----------------------------------------------

      {
        Sid    = "TerraformStateKMS"
        Effect = "Allow"

        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]

        Resource = aws_kms_key.terraform_state.arn
      },

      # ----------------------------------------------
      # EC2 / VPC / Networking
      # ----------------------------------------------

      {
        Sid    = "TerraformEC2Networking"
        Effect = "Allow"

        Action = [
          "ec2:Describe*",

          "ec2:CreateVpc",
          "ec2:DeleteVpc",
          "ec2:ModifyVpcAttribute",

          "ec2:CreateSubnet",
          "ec2:DeleteSubnet",
          "ec2:ModifySubnetAttribute",

          "ec2:CreateRouteTable",
          "ec2:DeleteRouteTable",
          "ec2:AssociateRouteTable",
          "ec2:DisassociateRouteTable",

          "ec2:CreateRoute",
          "ec2:ReplaceRoute",
          "ec2:DeleteRoute",

          "ec2:CreateInternetGateway",
          "ec2:DeleteInternetGateway",
          "ec2:AttachInternetGateway",
          "ec2:DetachInternetGateway",

          "ec2:AllocateAddress",
          "ec2:AssociateAddress",
          "ec2:DisassociateAddress",
          "ec2:ReleaseAddress",

          "ec2:CreateNatGateway",
          "ec2:DeleteNatGateway",

          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",

          "ec2:RunInstances",
          "ec2:TerminateInstances",

          "ec2:CreateTags",
          "ec2:DeleteTags"
        ]

        Resource = "*"
      },

      # ----------------------------------------------
      # IAM resources managed by Terraform
      # ----------------------------------------------

      {
        Sid    = "TerraformIAM"
        Effect = "Allow"

        Action = [
          "iam:Get*",
          "iam:List*",

          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:UpdateAssumeRolePolicy",

          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",

          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",

          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",

          "iam:PassRole"
        ]

        Resource = "*"
      },

      # ----------------------------------------------
      # Identity
      # ----------------------------------------------

      {
        Sid    = "TerraformSTS"
        Effect = "Allow"

        Action = [
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

output "terraform_state_kms_key_arn" {
  description = "KMS key ARN used to encrypt the Terraform state bucket"

  value = aws_kms_key.terraform_state.arn
}