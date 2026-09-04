resource "aws_instance" "private" {
  ami           = var.ami_id
  instance_type = var.instance_type

  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  associate_public_ip_address = false

  iam_instance_profile = var.iam_instance_profile
  metadata_options {
    http_tokens = "required"
  }
  root_block_device {
    encrypted = true
  }
  tags = {
    Name        = "sre-${var.environment}-private-ec2"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "sre-aws-terraform-platform"
  }
}