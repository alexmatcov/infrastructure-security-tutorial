# Interpreting Checkov Results and Project Insecurities 

We can interpret the results from the vulnerabilities seen. There will be multiple vulnerabilities so maybe we need some more steps after this one to fix the vulnerabilities

If you open the file `checkov-output.txt`, you can see a very long list of issues. Let's scroll through it a little more and see what issues came up. 

First, you can see the total number of checks that Checkov ran against your Terraform files. 
`Passed checks: 17, Failed checks: 27, Skipped checks: 0`

Then each of the 44 checks are listed with its name, and whether it passed or failed. For example, the check:
`Check: CKV_AWS_93: "Ensure S3 bucket policy does not lockout all but root user. (Prevent lockouts needing root account fixes)"` is shown first, and it clearly passes: `PASSED for resource: aws_s3_bucket.data_bucket`. Checkov even includes where the pass occurs in the file, and a link to the documentation for this specific check. 

If you keep scrolling through the document, you can see the failed checks. Let's pick a few to focus on and fix in our project. 


## CKV_AWS_53-56: S3 bucket publicly accessible ⚠ CRITICAL

Search for Check CKV_AWS_53-56 in the `checkov-outputs.txt` file. The next 4 checks all refer to the public accessibility of the S3 bucket. You can see the vulnerable section of code listed for each of these checks. All of the flags are set to false, meaning that there are no blocks to the public accessibility. This is a serious security issue as you do not want your S3 bucket to be publically accessible.

## CKV_AWS_19: S3 bucket not encrypted ⚠ HIGH


## CKV_AWS_24: Security group allows SSH from 0.0.0.0/0 ⚠ HIGH

## CKV_AWS_17: RDS database publicly accessible ⚠ CRITICAL

## CKV_AWS_226: Hardcoded database password ⚠ HIGH
