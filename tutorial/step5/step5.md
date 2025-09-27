# Integrating with CI/CD pipeline

Integrating Checkov in the CI/CD pipeline is essential to ensure that IaC configurations are secure from vulnerabilities before deployment. By integrating Checkov into the pipeline, it will help to catch vulnerabilities early and prevent insecure resources from reaching production. 

In this tutorial, you will be implementing Checkov as a pre-commit hook. This ensures that your IaC is scanned before you commit to version control. Only scanned, secure code will be added to the repository. 

## Adding Checkov as a Pre-Commit Hook

First, you need to install pre-commit:
```
pip install pre-commit
```{{exec}}

Now, create a file called `.pre-commit-config.yaml` and copy and paste the Checkov pre-commit hook code:
```
repos:
  - repo: https://github.com/bridgecrewio/checkov.git
    rev: '3.2.471'
    hooks:
      - id: checkov
```{{copy}}

Now you need to install this hook by running:
```
pre-commit install
```{{exec}}

Now, Checkov will successfully run with every commit!