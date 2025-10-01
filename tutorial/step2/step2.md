# Using Checkov

Now that you have learned about the Terraform architecture, let's start learning how to use [Checkov](checkov.io). 

In the terminal, you can see there is a script running to install pipx and Checkov. This means that you will NOT need to install Checkov, but can do so if you want by running this command:
```
pipx install checkov
```{{copy}}

Now we can use Checkov to scan our IaC. In this case, it will scan our Terraform files.

```
cd terraform-project
checkov -d . > checkov-outputs.txt
```{{exec}}

The `-d` told Checkov to look in a specific directory. You can run Checkov in any directory, or for any file you want. A complete list of commands can be found by running

```
checkov -h
```{{copy}}

Let's continue to the next step to interpret the Checkov outputs. 