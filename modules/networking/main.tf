resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "sre-aws-terraform-platform"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[0]
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment}-public-a"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "sre-aws-terraform-platform"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[1]
  availability_zone       = var.availability_zones[1]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment}-public-b"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "sre-aws-terraform-platform"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name        = "${var.environment}-igw"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "sre-aws-terraform-platform"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name        = "${var.environment}-public-rt"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "sre-aws-terraform-platform"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[0]
  availability_zone = var.availability_zones[0]

  tags = {
    Name        = "${var.environment}-private-a"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "sre-aws-terraform-platform"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[1]
  availability_zone = var.availability_zones[1]

  tags = {
    Name        = "${var.environment}-private-b"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "sre-aws-terraform-platform"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "${var.environment}-nat-eip"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "sre-aws-terraform-platform"
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  depends_on = [
    aws_internet_gateway.this
  ]

  tags = {
    Name        = "${var.environment}-nat"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "sre-aws-terraform-platform"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name        = "${var.environment}-private-rt"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "sre-aws-terraform-platform"
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}