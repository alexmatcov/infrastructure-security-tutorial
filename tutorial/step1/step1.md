# Understanding the Terraform Infrastructure

![Terraform Logo](../../images/tff.png)

Before we start scanning for security vulnerabilities, let's understand the infrastructure we're working with. This tutorial uses a sample AWS infrastructure that represents a typical web application architecture.

## Infrastructure Overview

Our Terraform project creates the following AWS resources:

### 1. **VPC and Networking**
- A Virtual Private Cloud (VPC) with CIDR block 10.0.0.0/16
- One public subnet (10.0.1.0/24) for web-facing resources
- Two private subnets (10.0.2.0/24 and 10.0.3.0/24) for the database

### 2. **S3 Storage Bucket**
- An S3 bucket named `company-data-bucket` for storing application data
- This bucket is intended to store sensitive company information and user uploads

### 3. **EC2 Web Server**
- A t2.micro EC2 instance running Amazon Linux 2
- Serves as the application web server
- Has a 20GB root volume for the operating system and application files

### 4. **RDS PostgreSQL Database**
- A PostgreSQL database (version 14.7) on a db.t3.micro instance
- Stores application data, user information, and transaction records
- 20GB of allocated storage

### 5. **Security Groups**
- Web security group controlling access to the EC2 instance
- Database security group controlling access to the RDS instance

## Viewing the Terraform Files

The environment has been set up with three main Terraform files that you can explore in the editor or terminal:
- `main.tf` - Contains all resource definitions
- `variables.tf` - Defines input variables
- `outputs.tf` - Defines outputs after infrastructure is created

## What Makes This Infrastructure Vulnerable?

While this infrastructure might look functional, it contains multiple security misconfigurations that could expose your organization to serious risks:

- **Public Exposure**: Resources that should be private are accessible from the internet
- **Missing Encryption**: Sensitive data stored without encryption
- **Weak Access Controls**: Overly permissive security rules
- **Poor Credential Management**: Hardcoded passwords and secrets
- **Lack of Logging**: No audit trails for security events

In the next step, we'll use Checkov to automatically identify these vulnerabilities!

## Architecture Diagram

**Internet**  
&nbsp;&nbsp;&nbsp;&nbsp;↓  
**[Security Group]** ← *SSH/HTTP open to 0.0.0.0/0*  
&nbsp;&nbsp;&nbsp;&nbsp;↓  
**[EC2 Web Server]** ← *Unencrypted volume, Public IP*  
&nbsp;&nbsp;&nbsp;&nbsp;↓  
**[Security Group]** ← *Database port open to 0.0.0.0/0*  
&nbsp;&nbsp;&nbsp;&nbsp;↓  
**[RDS Database]** ← *Publicly accessible, No encryption, Hardcoded password*  
&nbsp;&nbsp;&nbsp;&nbsp;↓  
**[S3 Bucket]** ← *Public access enabled, No encryption*

---

This setup represents a common but dangerous configuration pattern that Checkov will help us identify and fix.