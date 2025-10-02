# How to fix those problems

This is the step where we will show how to fix the vulnerabilities. This includes going to the location of the vulnerability and guiding the user to what changes need to be made (and why it is a good fix for that vulnerability)

## CKV_AWS_53-56: S3 bucket publicly accessible ⚠ CRITICAL
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

## CKV_AWS_19: S3 bucket not encrypted ⚠ HIGH

## CKV_AWS_24: Security group allows SSH from 0.0.0.0/0 ⚠ HIGH

## CKV_AWS_17: RDS database publicly accessible ⚠ CRITICAL

## CKV_AWS_226: Hardcoded database password ⚠ HIGH

