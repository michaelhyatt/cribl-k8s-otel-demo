# Deploy the demo with Terraform on EKS

## Init
```
terraform init
```

## Setup
Can take over 10-15 minutes. EKS provisioning is slo-o-ow.
```
terraform apply -auto-approve -var-file main.tfvars
```

## Connect `kubeconfig` to the cluster
```
aws eks --region $(terraform output -raw region) update-kubeconfig --alias eks-cluster --name $(terraform output -raw cluster_name)
```

## Workflow
Follow the deployment steps outlined in [`Local Setup` section](../../README.md). Skip the `ngrok` part. Use the public hostname of the cluster ingress for Kibana (port 5601), the app UI and loadgen UI (port 8080), and Search replay (port 10200).

## Get Kibana URL
```
kubectl get service kibana-kb-http -n elastic -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' | awk '{print "http://"$0":5601"}'
```

## Destroy
```
terraform destroy -auto-approve -var-file main.tfvars
```