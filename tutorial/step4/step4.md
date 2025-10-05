# How to fix those problems

This is the step where we will show how to fix the vulnerabilities. This includes going to the location of the vulnerability and guiding the user to what changes need to be made (and why it is a good fix for that vulnerability)

**Tip:** The code includes comments marking each vulnerability with the text "VULNERABILITY". You can use your IDE's search function (Ctrl+F or Cmd+F) to quickly find these in the `main.tf` file and fix them.

## Fix 1: S3 bucket publicly accessible (CKV_AWS_53-56)
```
    resource "aws_s3_bucket_public_access_block" "data_bucket" {
    bucket = aws_s3_bucket.data_bucket.id

    block_public_acls       = false
    block_public_policy     = false
    ignore_public_acls      = false
    restrict_public_buckets = false
    }
```

We can see from the vulnerable code listed for this vulnerability, all of the public access blocks are set to false. This means that none of the security blockers are active, which allow public access. In order to change this, we want to set each of the blockers to true. Let's make those changes in the correct spot in the `main.tf` file. The resulting section should look like this:

```
    resource "aws_s3_bucket_public_access_block" "data_bucket" {
    bucket = aws_s3_bucket.data_bucket.id

    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
    }
```

## Fix 2: S3 bucket not encrypted with KMS by deafult (CKV_AWS_145)

You can add in the missing aws_s3_bucket_server_side_encryption_configuration resource by copying the following code into the main.tf document. This encryption resource should be placed after the aws_s3_bucket_public_access_block. 

```
resource "aws_s3_bucket_server_side_encryption_configuration" "data_bucket" {
  bucket = aws_s3_bucket.data_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.mykey.arn
      sse_algorithm = "aws:kms"
    }
  }
}
```{{copy}}

## Fix  3: Security group allows SSH from 0.0.0.0/0 (CKV_AWS_24)

For this tutorial, we don't actually need SSH access at all, so the best fix is to remove this entire ingress block. Delete these lines from the security group. This eliminates the attack surface completely. If you did need SSH access in a real scenario, you would replace 0.0.0.0/0 with your specific IP range.

In the `main.tf` file, find the security group resource `aws_security_group.db_sg`. You'll see an ingress rule that allows SSH from anywhere:

```
ingress {
  description = "SSH from anywhere"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
```

## Fix 4: RDS database publicly accessible (CKV_AWS_17) 

In the main.tf file, locate the aws_db_instance resource named "database". Find the line that says publicly_accessible = true. This setting gives the database a public IP address. Change it to false: 

```
publicly_accessible = false
```{{copy}}

This ensures the database can only be accessed from within the VPC, not from the internet. This is how databases should always be configured - accessible only to your application servers, not to the outside world.

## Fix 5: Base64 High Entropy String (CKV_AWS_6)

This check detects potential hardcoded secrets in your code. If you have a hardcoded password like `password = "password123"` in your `aws_db_instance` resource, you need to replace it with a variable.

First, add a variable definition to your `variables.tf` file:

```
variable "db_password" {
  description = "Database administrator password"
  type        = string
  sensitive   = true
}
```{{copy}}

Then in `main.tf`, replace the hardcoded password with the variable:
```hcl
password = var.db_password 
```

The `sensitive = true` flag prevents the password from being displayed in logs or console output. In production, you would provide this password through environment variables (`TF_VAR_db_password`) or use AWS Secrets Manager to retrieve it dynamically. Never commit passwords to version control.

## Fix 6: RDS auto minor version upgrades disabled (CKV_AWS_226) ⚠️ HIGH

In the same `aws_db_instance` resource, we need to add a setting to enable automatic minor version upgrades. Add this line to the database configuration:

```
auto_minor_version_upgrade = true
```{{copy}}

This tells AWS to automatically apply minor version updates (like PostgreSQL 14.7 to 14.8) that include security patches and bug fixes. These updates happen during your maintenance window and don't break compatibility. Major version upgrades (like PostgreSQL 14 to 15) still require manual approval.

## Checking Fixes

Now, when you run Checkov again against your repository, you should have all the checks passing! Every change you made addressed a real security vulnerability. This completes the scan-fail-fix-pass cycle: you identified issues with Checkov, fixed them, and verified the fixes pass. This workflow is fundamental to DevSecOps and helps you catch security problems before they reach production.

```
checkov -d . > checkov-outputs2.txt
```{{exec}}

