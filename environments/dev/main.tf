terraform {
  required_version = ">= 1.12.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.55"
    }
  }


  backend "s3" {
    bucket       = "sre-aws-terraform-state-015747469534"
    key          = "dev/terraform.tfstate"
    region       = "ap-south-1"
    profile      = "sre-lab"
    use_lockfile = true
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "sre-lab"
}
module "networking" {
  source = "../../modules/networking"

  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

data "aws_caller_identity" "current" {}

resource "aws_security_group" "private_ec2" {
  name        = "sre-dev-private-ec2"
  description = "Security group for private EC2"
  vpc_id      = module.networking.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ec2" {
  name = "sre-dev-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "ec2.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "sre-dev-ec2-role"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "sre-aws-terraform-platform"
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "sre-dev-ec2-profile"
  role = aws_iam_role.ec2.name


  tags = {
    Name        = "sre-dev-ec2-profile"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "sre-aws-terraform-platform"
  }
}

resource "aws_instance" "private" {
  ami           = var.ami_id
  instance_type = var.instance_type

  subnet_id                   = module.networking.private_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.private_ec2.id]
  associate_public_ip_address = false

  iam_instance_profile = aws_iam_instance_profile.ec2.name

  tags = {
    Name        = "sre-dev-private-ec2"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "sre-aws-terraform-platform"
  }
}