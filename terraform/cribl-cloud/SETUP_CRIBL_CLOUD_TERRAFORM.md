# Set up Cribl Cloud components using terraform

## Prerequisites
It obviously needs Terraform ;)

## IMPORTANT: Cribl Lake datasets creation
Don't run the file `lake.tf.dont_run` through Terraform, create the lake datasets manually. The reason is that destroying the datasets will not delete them, only mark them for deletion and they can't be recreated with `terraform apply` until they are fully deleted.

Manually create the following datasets in Cribl Cloud Lake before running the terraform script:
* otel_demo_otel_traces
* otel_demo_otel_metrics
* otel_demo_otel_logs

### Install terraform
```
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

## Setup
The providers works with env variables, but can work with credential files, as in the [example here](https://github.com/criblio/terraform-provider-criblio/tree/main?tab=readme-ov-file#authentication-methods). Change the `main.tf` file accordingly, if needed.

Client ID and client secret are available under Organization -> API Credentials. Requires Admin permissions.

### Environment variables setup
```bash
export CRIBL_CLIENT_ID="your-client-id"
export CRIBL_CLIENT_SECRET="your-client-secret"
export CRIBL_ORGANIZATION_ID="your-organization-id"
export CRIBL_WORKSPACE_ID="your-workspace-id"

# Optional: specify cloud domain (defaults to cribl.cloud)
export CRIBL_CLOUD_DOMAIN="cribl.cloud"

# Generate lake bucket name
export TF_VAR_lake_bucket_name="lake-${CRIBL_WORKSPACE_ID}-${CRIBL_ORGANIZATION_ID}"

# Edge settings
export TF_VAR_fleet_name=otel-demo-k8s-fleet

# Stream settings
export TF_VAR_stream_worker_group=otel-demo-k8s-wg
```

### Init terraform
```bash
terraform init
```

