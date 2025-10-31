# Set up Cribl Cloud components using terraform

## Prerequisites
It obviously needs Terraform ;)

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

# Optional: specify another cloud domain (defaults to cribl.cloud)
export CRIBL_CLOUD_DOMAIN="cribl-staging.cloud"


## Direct Terraform variable setting
# Edge settings
export TF_VAR_fleet_name=otel-demo-k8s-fleet

# Stream settings
export TF_VAR_worker_group_name=otel-demo-k8s-wg

# Lake bucket name setting 
export TF_VAR_lake_bucket_name="lake-${CRIBL_WORKSPACE_ID}-${CRIBL_ORGANIZATION_ID}"
```

### Init terraform
```bash
terraform init
```

## Deploy
```bash
terraform apply -auto-approve
```

## Destroy 
```bash
terraform destroy -auto-approve
```

## Known issues
* Destroying doesn't always work on k8s_disk_spool Search dataset. Delete it manually, if needed. It looks like a UI quirk, since the query shows it has been deleted:
* `dataset="$vt_datasets" id="k8s_edge_spool" | count` returns 1 after `apply` and 0 after `destroy`
