# Using Checkov

Now that you have learned about the Terraform architecture, let's start learning how to use [Checkov](checkov.io). 

In the terminal, you can see there is a script running to install pipx and Checkov. It will take a minute or two, so please wait while everything runs. Due to the configuration of Killer Coda, we have automated the process of installing Checkov using pipx. However, if you wanted to download it yourself, you could do so with the following command: 

```
pipx install checkov
```

When you see the easter egg, the script is done, and we can start using Checkov to scan our Terraform project: 

```
cd terraform-project
checkov -d . > checkov-outputs.txt
```{{exec}}

The `-d` tells Checkov to look in a specific directory. You can run Checkov in any directory, or on any file you want. A list of complete commands can be found by running:

```
checkov -h
```{{copy}}

Let's continue to the next step to interpret the Checkov output. 