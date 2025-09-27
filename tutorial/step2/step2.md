# Using Checkov

Now that you have learned about the Terraform architecture, let's start learning how to use [Checkov](checkov.io). 

First we need to install Checkov. We can do that by running the following command. 

```
pip install checkov
```{{exec}}

That's it! Now we can use Checkov to scan our IaC. In this case, it will scan our Terraform files.

```
checkov -d .
```{{exec}}

The `-d` told Checkov to look in a specific directory. You can run Checkov in any directory, or for any file you want. A complete list of commands can be found by running

```
checkov -h
```{{copy}}

Let's continue to the next step to interpret the Checkov outputs. 