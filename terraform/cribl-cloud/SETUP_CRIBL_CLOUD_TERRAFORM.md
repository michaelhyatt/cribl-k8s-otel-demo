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

# Other variables that are used to set up Helm charts
export CRIBL_STREAM_VERSION=4.14.0
export CRIBL_STREAM_WORKER_GROUP=otel-demo-k8s-wg
export CRIBL_STREAM_TOKEN="stream enrollment token from worker enrollment dialogue"
export CRIBL_STREAM_LEADER_URL="Leader URL from worker enrollment dialogue"
export CRIBL_EDGE_VERSION=${CRIBL_STREAM_VERSION}
export CRIBL_EDGE_FLEET=otel-demo-k8s-fleet
export CRIBL_EDGE_LEADER_URL=${CRIBL_STREAM_LEADER_URL}
export CRIBL_EDGE_TOKEN=${CRIBL_STREAM_TOKEN}

## Direct Terraform variable setting
# Edge settings
export TF_VAR_fleet_name=${CRIBL_EDGE_FLEET}

# Stream settings
export TF_VAR_worker_group_name=${CRIBL_STREAM_WORKER_GROUP}

# Lake bucket name setting
export TF_VAR_lake_bucket_name="lake-${CRIBL_WORKSPACE_ID}-${CRIBL_ORGANIZATION_ID}"
```

### Lakehouse creation
Lakehouse is awesome if you want to accelerate the Lake dashboards, but it may take a long time to set up (up to 20-30 mins at times). So, the creation of the Lakehouse is optional and is disabled by default. To enable it, set the following variable before running `terraform apply -auto-aprove`:
```bash
export TF_VAR_create_lakehouse=true
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
* Lakehouse creation may time out. Either re-run the `apply`, or 
