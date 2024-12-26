# Setup using Terraform on AWS EC2

## Setup
Edit `main.tfvars` and populate it with Stream, Edge parameters from Cribl.Cloud. Also, specify the pem file and the name of your key used to create EC2 instances. Give your instance a name and specify the region. Check that the AMI with Ubintu 24 Server is available in that region.
Run `terraform init` once in the `terraform` directory.

## Deploy
```
terraform apply -auto-approve -var-file main.tfvars
```

## Connecting to the instance
After the `apply` command finishes, it will display the public hostname of the provisioned EC2 server. It will contain:
* OTel demo app
    * App UI is available on http://ec2-xx-xx-xx-xx.us-west-2.compute.amazonaws.com:8080
    * Loadgen UI is available at http://ec2-xx-xx-xx-xx.us-west-2.compute.amazonaws.com:8080/loadgen/
* Kibana (with the rest of Elastic stack) http://ec2-xx-xx-xx-xx.us-west-2.compute.amazonaws.com:5601
* Stream HTTP source listening on  http://ec2-xx-xx-xx-xx.us-west-2.compute.amazonaws.com:10200
    * Use this value as the target of the `| send` operation in the Search dashboards for data replay.


## Clean-up
```
terraform destroy -auto-approve -var-file main.tfvars
```