# Setup using Terraform on AWS

## Deploy
```
terraform apply -auto-approve -var-file main.tfvars
```

## Clean-up
```
terraform destroy -auto-approve -var-file main.tfvars
```