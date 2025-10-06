# Interpreting Checkov Results and Project Insecurities 

Now that Checkov has scanned your infrastructure, let's examine the results to understand what security issues were found. In this step, you'll learn how to read Checkov's output, identify the most critical vulnerabilities, and understand why they matter. We'll focus on 6 key security issues that you'll fix in the next step.

If you open the file `terraform-project/checkov-output.txt`, you can see a very long list of checks. Let's scroll through it a little more and see what issues came up. 

First, you can see the total number of checks that Checkov ran against your Terraform files. 
`Passed checks: 87, Failed checks: 9, Skipped checks: 0`

Then each of the 96 checks are listed with its name, and whether it passed or failed. For example, the check:
`Check: CKV_AWS_41: "Ensure no hard coded AWS access key and secret key exists in provider"` is shown first, and it clearly passes: `PASSED for resource: aws.default`. Checkov even includes where the pass occurs in the file, and a link to the documentation for this specific check and how to fix the vulnerability. 

If you keep scrolling through the document, you can see the failed checks. Let's pick a few to focus on and fix in our project. 

## Vulnerability 1: S3 bucket publicly accessible (CKV_AWS_53-56)

Search for Check CKV_AWS_53 to 56 in the `checkov-outputs.txt` file. The next 4 checks all refer to the public accessibility of the S3 bucket. You can see the vulnerable section of code listed for each of these checks. All of the flags are set to false, meaning that there are no blocks to the public accessibility. This is a serious security issue as you do not want your S3 bucket to be publically accessible.

<details>
<summary><strong>💡 Hint </strong></summary>

Look for the `aws_s3_bucket_public_access_block` resource in your `main.tf` file. Notice that all four settings (`block_public_acls`, `block_public_policy`, `ignore_public_acls`, `restrict_public_buckets`) are set to `false`. What would happen if these were all set to `true`?
</details>


## Vulnerability 2: S3 bucket not encrypted with KMS by deafult (CKV_AWS_145)

Look for check: CKV_AWS_145: "Ensure that S3 buckets are encrypted with KMS by default" in the `checkov-outputs.txt` file. This check wants the S3 bucket encryption to be with Key Management Service (KMS). This encryption ensures encrypted data that only authorized users can access and decrypt. We need to create a resource called "aws_s3_bucket_server_side_encryption_configuration" in order to fix this security vulneravility. 

<details>
<summary><strong>💡 Hint </strong></summary>

Notice that there's no `aws_s3_bucket_server_side_encryption_configuration` resource in the code at all. This resource needs to be added to enable encryption. Think about where in the file this resource should be placed - it should reference the S3 bucket we created.
</details>


## Vulnerability 3: Security group allows SSH from 0.0.0.0/0 (CKV_AWS_24)

Search for Check CKV_AWS_24 in the `checkov-outputs.txt` file. This check flags that SSH access (port 22) is open to the entire internet with the CIDR block `0.0.0.0/0`. This means anyone from anywhere can attempt to connect to your server via SSH. This is a significant security risk as it exposes your infrastructure to brute force attacks, where automated bots continuously try different password combinations. SSH should only be accessible from trusted IP addresses, such as your corporate network or VPN, not from the entire internet.

<details>
<summary><strong>💡 Hint </strong></summary>

Find the security group resource `aws_security_group.db_sg` and look for the ingress rule with port 22. The `cidr_blocks = ["0.0.0.0/0"]` means "from anywhere on the internet".
</details>


## Vulnerability 4: RDS database publicly accessible (CKV_AWS_17)

Look for Check CKV_AWS_17 in the `checkov-outputs.txt` file. This critical vulnerability shows that the RDS database has `publicly_accessible = true`, which gives it a public IP address that can be reached from the internet. Databases contain your most sensitive information: user accounts, passwords, financial records, and should never be directly accessible from the internet. This setting allows attackers to bypass your application security and attempt to access the database directly, making it vulnerable to SQL injection, brute force attacks, and data breaches.

<details>
<summary><strong>💡 Hint </strong></summary>

Find the `aws_db_instance` resource in `main.tf` and locate the `publicly_accessible` setting. This is a simple boolean value. What should it be set to for a production database that should only be accessed from within the VPC?
</details>


## Vulnerability 5: Base64 High Entropy String (CKV_AWS_6)

Search for Check CKV_AWS_6 in the `checkov-outputs.txt` file. This check uses entropy analysis to detect potential hardcoded secrets, passwords, or API keys in your code. High entropy strings that look like encoded credentials are flagged as security risks. In our case, this may flag the database password if it's hardcoded directly in the Terraform file. Hardcoded credentials are dangerous because they end up in version control, state files, and logs where they can be discovered by attackers. Passwords should never be stored directly in code - they should be managed through secure secret management services like AWS Secrets Manager or passed as sensitive variables.

<details>
<summary><strong>💡 Hint </strong></summary>

Check the `aws_db_instance` resource for a `password` field. Is the password written directly in the code? Think about how you could use Terraform variables (defined in `variables.tf`) instead to keep sensitive information out of your code files. Look for the `variable` keyword and `sensitive = true` attribute.
</details>


## Vulnerability 6: RDS auto minor version upgrades disabled (CKV_AWS_226)

Find Check CKV_AWS_226 in the `checkov-outputs.txt` file. This check indicates that automatic minor version upgrades are not enabled for the RDS database. Minor version upgrades include critical security patches and bug fixes. Without this setting enabled, your database remains vulnerable to known security issues that have already been patched by AWS. You would need to manually track and apply these updates, which increases the risk of missing important security patches.

<details>
<summary><strong>💡 Hint </strong></summary>

Look at the `aws_db_instance` resource. Notice there's no `auto_minor_version_upgrade` setting at all. This is a configuration that needs to be added to the resource. What value should it have to enable automatic security patches?
</details>

---

## Summary and Next Steps

We've identified **6 major vulnerabilities** in our infrastructure related to S3 bucket and database exposed to the internet, missing encryption, weak access controls, and hardcoded secrets.

These are common real-world security mistakes that Checkov caught automatically!

**Challenge:** Before moving to the next step, try fixing the vulnerabilities yourself and use the hints above if you need extra guidance.

When you're ready (or if you need more guidance), proceed to the next step where we'll walk through together fixing each vulnerability with detailed explanations.