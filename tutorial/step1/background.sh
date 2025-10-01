#!/bin/bash

# Background script to set up the Terraform environment
# This runs automatically when the step starts

echo "Setting up Terraform environment..." > /tmp/setup.log

# Update package list
apt-get update -qq > /dev/null 2>&1

apt install pipx

pipx install checkov

# Add pipx to PATH for current session
export PATH="$PATH:/root/.local/share/pipx/venvs/checkov"
echo 'export PATH="$PATH:/root/.local/share/pipx/venvs/checkov"' >> /root/.bashrc

echo "pipx installed and configured" >> /tmp/setup.log

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

# S3 Bucket - VULNERABILITY: Public access enabled
resource "aws_s3_bucket" "data_bucket" {
  bucket = "company-data-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "CompanyDataBucket"
    Environment = "Production"
  }
}

# VULNERABILITY: Bucket is publicly accessible
resource "aws_s3_bucket_public_access_block" "data_bucket" {
  bucket = aws_s3_bucket.data_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# VULNERABILITY: No encryption at rest
resource "aws_s3_bucket_versioning" "data_bucket" {
  bucket = aws_s3_bucket.data_bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}

# Random ID for unique bucket naming
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# EC2 Instance - VULNERABILITY: No encryption for root volume
resource "aws_instance" "web_server" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  
  # VULNERABILITY: No encryption on root volume
  root_block_device {
    encrypted = false
    volume_size = 20
  }

  # VULNERABILITY: Public IP assigned
  associate_public_ip_address = true

  tags = {
    Name = "WebServer"
  }
}

# Security Group - VULNERABILITY: Overly permissive rules
resource "aws_security_group" "web_sg" {
  name        = "web-security-group"
  description = "Security group for web server"
  vpc_id      = aws_vpc.main.id

  # VULNERABILITY: SSH open to the world (0.0.0.0/0)
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # VULNERABILITY: HTTP open to the world
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # VULNERABILITY: All outbound traffic allowed
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "WebSecurityGroup"
  }
}

# VPC Configuration
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  # VULNERABILITY: Flow logs not enabled
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "MainVPC"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  
  # VULNERABILITY: Auto-assign public IP
  map_public_ip_on_launch = true

  tags = {
    Name = "PublicSubnet"
  }
}

# RDS Database - VULNERABILITY: Multiple security issues
resource "aws_db_instance" "database" {
  identifier           = "company-database"
  engine              = "postgres"
  engine_version      = "14.7"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  
  db_name  = "companydb"
  username = "admin"
  password = "password123"  # VULNERABILITY: Hardcoded password
  
  # VULNERABILITY: Publicly accessible database
  publicly_accessible = true
  
  # VULNERABILITY: No encryption at rest
  storage_encrypted = false
  
  # VULNERABILITY: Deletion protection disabled
  deletion_protection = false
  
  # VULNERABILITY: No backup retention
  backup_retention_period = 0
  
  # VULNERABILITY: Skip final snapshot
  skip_final_snapshot = true
  
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.database.name

  tags = {
    Name = "CompanyDatabase"
  }
}

resource "aws_security_group" "db_sg" {
  name        = "database-security-group"
  description = "Security group for database"
  vpc_id      = aws_vpc.main.id

  # VULNERABILITY: Database port open to the world
  ingress {
    description = "PostgreSQL from anywhere"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

resource "aws_subnet" "private_1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "PrivateSubnet1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
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
EOF

# Create variables.tf
cat > variables.tf << 'EOF'
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
  default     = "ami-0c55b159cbfafe1f0"
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

output "web_server_public_ip" {
  description = "Public IP of the web server"
  value       = aws_instance.web_server.public_ip
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