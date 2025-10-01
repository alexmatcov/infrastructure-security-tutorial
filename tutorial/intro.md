# Using Checkov for Infrastructure Security Scanning

### By: Alexandru Matcov (matcov@kth.se) and Phoebe Schwartz (phoebes@kth.se)

## Intended Learning Outcomes
- Understand the importance of Infrastructure as Code security and its role in DevSecOps workflows.
- Identify common security misconfigurations in Terraform code.
- Install and configure Checkov for static analysis of IaC.
- Use Checkov to scan Terraform projects and interpret the results, including the vulnerability classifications.
- Remediate critical security findings in Terraform code. 
- Demonstrate the scan-fail-fix-pass cycle for infrastructure security.
- Integrate Checkov into a CI/CD pipeline to automate security scanning. 
- Reflect on the impact of automated IaC security scanning in the software development lifecycle. 

## DevOps Importance
Infrastructure security integration throughout the development lifecycle is an important DevOps practice. IaC security scanning is an essential part of ensuring security, and demonstrates core DevOps principles such as: automation, continuous integration, and catching security issues before deployment. 

## Background

Infrastructure and Code (IaC) allows teams to define, deploy, and manage cloud resources using code. This is an essential DevOps practice because it allows for automation, repeatability, and version control. However, this means there are more potentials for security challenges including vulnerabilities of publicly accessible storage, overly permissive network rules, and unencrypted data. 

Traditional security practices often end up fixing and monitoring post-deplotment, but this can leave potential for expensive and extensive security vulnerabilities. By integrating security checks early in the development lifecycle, even before the infrastructure is provisioned, teams can prevent these misconfigurations from being deploted. This is a "shift-left" approach to DevSecOps that emphasizes the importance of embedding security into every stage of the DevOps pipeline. 

# What is Checkov?

![Checkov Logo](../images/checkov_blue_logo.png)

[Checkov](https://www.checkov.io/) is an open source, static analysis tool designed to scan IaC templates (Terraform, Docker, Kubernetes, and more) for security and compliance issues. By automating the detection of vulnerabilities, Checkov can help to identify and remidiate problems in IaC early. 