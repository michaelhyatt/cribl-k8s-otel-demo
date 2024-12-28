# Deploy the demo with Terraform on EKS

## Init
Create and update `terraform.tfvars`
```
cp terraform_example.tfvars terraform.tfvars
terraform init
```

## Setup
Can take over 10-15 minutes. EKS provisioning is slo-o-ow.
```
terraform apply -auto-approve
```

## Connect `kubeconfig` to the cluster
The terraform script will update the `kubeconfig`, so you can use `kubectl` or `k9s` straight away after it finises. In case it doesn't this is what it will do:
```
aws eks --region $(terraform output -raw region) update-kubeconfig --alias eks-cluster --name $(terraform output -raw cluster_name)
```

## Workflow
The Terraform script is following the deployment steps outlined in [`Local Setup` section](../../README.md) skipping the `ngrok` part. Use the displaayed URLs of the services (Kibana, app and Stream HTTP) to drive the app.

Just in case the URLs get lost, here is how to display them.

### Get Kibana URL
You know, to open in a browser window. Takes 5 mins or so to update the DNS name.
```
kubectl get service kibana-kb-http -n elastic -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' | awk '{print "http://"$0":5601"}'
```

### Get Stream replay URL
To be populated in Search tashboards for data replay.
```
kubectl get service cribl-worker-logstream-workergroup -n cribl -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' | awk '{print "http://"$0":10200"}'
```

### Get app and loadgen UI URL 
Not a must, but nice to have for access to the app and loadgen (at /loadgen/)
```
kubectl get service opentelemetry-demo-frontendproxy -n otel-demo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' | awk '{print "http://"$0":8080"}'
```

## Destroy
```
terraform destroy -auto-approve
```