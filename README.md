# azure-function-terraform

```
az login
terraform init
terraform plan -out main.tfplan
terraform apply main.tfplan
```
 - Currently state file is stored locally.
 - Create a managed identity and assing permission to create resources.

# Updating functions with dependancy packages 
 ```
pip3 install --upgrade pip
cd functionappdirectory
rm -rf .python_packages
pip3.6 install --target=".python_packages/lib/site-packages" -r requirements.txt
 ```
 - We are using the same python version in appservice plan