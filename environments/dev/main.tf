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
  region = var.aws_region
}
module "networking" {
  source = "../../modules/networking"

  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}


module "iam" {
  source = "../../modules/iam"

  environment = var.environment
}
module "compute" {
  source = "../../modules/compute"

  environment          = var.environment
  ami_id               = var.ami_id
  instance_type        = var.instance_type
  subnet_id            = module.networking.private_subnet_ids[0]
  security_group_id    = aws_security_group.private_ec2.id
  iam_instance_profile = module.iam.instance_profile_name
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

