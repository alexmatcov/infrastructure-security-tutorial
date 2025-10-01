#!/bin/bash

# Background script to set up the Terraform environment
# This runs automatically when the step starts

echo "Setting up Terraform environment..." > /tmp/setup.log

# Install Terraform if not already installed
if ! command -v terraform &> /dev/null; then
    echo "Installing Terraform..." >> /tmp/setup.log
    wget -q https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
    unzip -q terraform_1.6.0_linux_amd64.zip
    mv terraform /usr/local/bin/
    rm terraform_1.6.0_linux_amd64.zip
    echo "Terraform installed" >> /tmp/setup.log
fi

# Create project directory
mkdir -p /root/terraform-project
cd /root/terraform-project

# Create main.tf
cat > main.tf << 'EOF'
# Main Terraform Configuration
# This file contains intentional security misconfigurations for educational purposes

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  # Skip credentials for tutorial purposes
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  
  # Use mock credentials
  access_key = "mock_access_key"
  secret_key = "mock_secret_key"
}

# Random ID for unique bucket naming
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# VULNERABILITY 1 & 2: S3 Bucket - Public access and no encryption
resource "aws_s3_bucket" "data_bucket" {
  bucket = "company-data-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "CompanyDataBucket"
    Environment = "Production"
  }
}

# VULNERABILITY 1: Bucket is publicly accessible
resource "aws_s3_bucket_public_access_block" "data_bucket" {
  bucket = aws_s3_bucket.data_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Note: No encryption configured (VULNERABILITY 2)
# Missing: aws_s3_bucket_server_side_encryption_configuration resource

# VPC for RDS
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "MainVPC"
  }
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "PrivateSubnet1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "PrivateSubnet2"
  }
}

resource "aws_db_subnet_group" "database" {
  name       = "database-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = {
    Name = "DatabaseSubnetGroup"
  }
}

# VULNERABILITY 3: Security group with overly permissive SSH access
resource "aws_security_group" "db_sg" {
  name        = "database-security-group"
  description = "Security group for database"
  vpc_id      = aws_vpc.main.id

  # VULNERABILITY 3: SSH open to the world (0.0.0.0/0)
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Database port for legitimate access
  ingress {
    description = "PostgreSQL"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "DatabaseSecurityGroup"
  }
}

# VULNERABILITY 4 & 5: RDS Database - Publicly accessible and hardcoded password
resource "aws_db_instance" "database" {
  identifier          = "company-database"
  engine              = "postgres"
  engine_version      = "14.7"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  
  db_name  = "companydb"
  username = "admin"
  password = "password123"  # VULNERABILITY 5: Hardcoded password
  
  # VULNERABILITY 4: Publicly accessible database
  publicly_accessible = true
  
  # Note: Storage encryption disabled by default
  storage_encrypted = false
  
  skip_final_snapshot = true
  
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.database.name

  tags = {
    Name = "CompanyDatabase"
  }
}
EOF

# Create variables.tf
cat > variables.tf << 'EOF'
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}
EOF

# Create outputs.tf
cat > outputs.tf << 'EOF'
output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.data_bucket.id
}

output "database_endpoint" {
  description = "Database connection endpoint"
  value       = aws_db_instance.database.endpoint
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}
EOF


# Initialize Terraform
echo "Initializing Terraform..." >> /tmp/setup.log
terraform init > /dev/null 2>&1

echo "Setup complete!" >> /tmp/setup.log
echo "done" > /tmp/finished