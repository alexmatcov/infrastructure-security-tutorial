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

# Create main.tf with only the 6 tutorial vulnerabilities
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

resource "aws_s3_bucket" "data_bucket" {
  bucket = "company-data-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "CompanyDataBucket"
    Environment = "Production"
  }
}

# VULNERABILITY 1: Bucket is publicly accessible (CKV_AWS_53-56, CKV2_AWS_6)
resource "aws_s3_bucket_public_access_block" "data_bucket" {
  bucket = aws_s3_bucket.data_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# VULNERABILITY 2: No KMS encryption configured (CKV_AWS_145)
# Paste the missing encryption configuration below

resource "aws_s3_bucket_versioning" "data_bucket" {
  bucket = aws_s3_bucket.data_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "data_bucket" {
  bucket = aws_s3_bucket.data_bucket.id

  target_bucket = aws_s3_bucket.data_bucket.id
  target_prefix = "log/"
}

# Add abort incomplete multipart uploads
resource "aws_s3_bucket_lifecycle_configuration" "data_bucket" {
  bucket = aws_s3_bucket.data_bucket.id

  rule {
    id     = "log"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Add S3 event notifications
resource "aws_s3_bucket_notification" "data_bucket" {
  bucket = aws_s3_bucket.data_bucket.id
}

# Add cross-region replication (requires destination bucket)
resource "aws_s3_bucket" "replica" {
  provider = aws.replica
  bucket   = "company-data-bucket-replica-${random_id.bucket_suffix.hex}"
}

# KMS key for replica bucket encryption (in replica region)
resource "aws_kms_key" "s3_replica" {
  provider                = aws.replica
  description             = "KMS key for S3 replica encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action   = "kms:*"
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:CallerAccount" = "123456789012"
          }
        }
      },
      {
        Sid    = "Allow S3 to use the key"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })
}

# Encryption configuration for replica bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.replica.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_replica.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Public access block for replica bucket
resource "aws_s3_bucket_public_access_block" "replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.replica.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Logging for replica bucket
resource "aws_s3_bucket_logging" "replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.replica.id

  target_bucket = aws_s3_bucket.replica.id
  target_prefix = "replica-log/"
}

# Lifecycle configuration for replica bucket
resource "aws_s3_bucket_lifecycle_configuration" "replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.replica.id

  rule {
    id     = "replica-log"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Event notifications for replica bucket
resource "aws_s3_bucket_notification" "replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.replica.id
}

provider "aws" {
  alias  = "replica"
  region = "us-west-2"
  
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  
  access_key = "mock_access_key"
  secret_key = "mock_secret_key"
}

resource "aws_iam_role" "replication" {
  name = "s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "replication" {
  name = "s3-replication-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.data_bucket.arn
        ]
      },
      {
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.data_bucket.arn}/*"
        ]
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete"
        ]
        Effect = "Allow"
        Resource = "${aws_s3_bucket.replica.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}

resource "aws_s3_bucket_versioning" "replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.replica.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_replication_configuration" "replication" {
  depends_on = [aws_s3_bucket_versioning.data_bucket]
  
  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.data_bucket.id

  rule {
    id     = "replicate-all"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.replica.arn
      storage_class = "STANDARD"
    }
  }
}

# VPC for RDS
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "MainVPC"
  }
}

# KMS encryption and retention
resource "aws_kms_key" "cloudwatch" {
  description             = "KMS key for CloudWatch logs"
  policy      = <<POLICY
  {
    "Version": "2012-10-17",
    "Id": "default",
    "Statement": [
      {
        "Sid": "DefaultAllow",
        "Effect": "Allow",
        "Principal": {
          "AWS": "arn:aws:iam::123456789012:root"
        },
        "Action": "kms:*",
        "Resource": "*"
      }
    ]
  }
POLICY
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.vpc_flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}

resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name              = "/aws/vpc/flow-logs"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.cloudwatch.arn
}

resource "aws_iam_role" "vpc_flow_log_role" {
  name = "vpc-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

# Specific resources instead of wildcard
resource "aws_iam_role_policy" "vpc_flow_log_policy" {
  name = "vpc-flow-log-policy"
  role = aws_iam_role.vpc_flow_log_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect = "Allow"
        Resource = [
          aws_cloudwatch_log_group.vpc_flow_log.arn,
          "${aws_cloudwatch_log_group.vpc_flow_log.arn}:*"
        ]
      }
    ]
  })
}

# Restrict default security group
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  # No ingress or egress rules - completely restrictive
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

# VULNERABILITY 3: Security group with overly permissive SSH access (CKV_AWS_24)
resource "aws_security_group" "db_sg" {
  name        = "database-security-group"
  description = "Security group for database"
  vpc_id      = aws_vpc.main.id

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

  # Make egress more restrictive
  egress {
    description = "HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "PostgreSQL to VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = {
    Name = "DatabaseSecurityGroup"
  }
}

# Add explicit KMS key policy
resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action   = "kms:*"
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:CallerAccount" = "123456789012"
          }
        }
      },
      {
        Sid    = "Allow RDS to use the key"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM role for enhanced monitoring
resource "aws_iam_role" "rds_monitoring_role" {
  name = "rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring_policy" {
  role       = aws_iam_role.rds_monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# DB parameter group with SSL enforcement
resource "aws_db_parameter_group" "postgres" {
  name   = "postgres-logging"
  family = "postgres14"

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }
}

resource "aws_db_instance" "database" {
  identifier          = "company-database"
  engine              = "postgres"
  engine_version      = "14.7"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  
  db_name  = "companydb"
  username = "admin"
  # VULNERABILITY 5: Hardcoded password (CKV_SECRET_6)
  password = "password123"  
  
  # VULNERABILITY 4: Publicly accessible database (CKV_AWS_17)
  publicly_accessible = true
  
  # Enable storage encryption
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn
  
  # VULNERABILITY 6: Auto minor version upgrade disabled (CKV_AWS_226)
  auto_minor_version_upgrade = false
  
  # Enable Multi-AZ
  multi_az = true
  
  # Enable enhanced monitoring
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  monitoring_interval             = 60
  monitoring_role_arn            = aws_iam_role.rds_monitoring_role.arn
  
  # Enable Performance Insights
  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.rds.arn
  
  # Enable IAM authentication
  iam_database_authentication_enabled = true
  
  # Enable deletion protection
  deletion_protection = true
  
  # Enable copy tags to snapshots
  copy_tags_to_snapshot = true
  
  skip_final_snapshot       = true
  final_snapshot_identifier = "company-database-final-snapshot"
  
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.database.name
  parameter_group_name   = aws_db_parameter_group.postgres.name

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