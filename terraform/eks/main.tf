# The provisioning is done in other files, this file is used to retrieve the external IPs of the services

# Use kubernetes provider to retrieve the external IPs
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    command     = "aws"
  }
}

data "kubernetes_service" "cribl_worker_service" {
  metadata {
    name      = "cribl-worker-logstream-workergroup"
    namespace = "cribl"
  }
}

data "kubernetes_service" "kibana_service" {
  metadata {
    name      = "kibana-kb-http"
    namespace = "elastic"
  }
}

data "kubernetes_service" "app_service" {
  metadata {
    name      = "opentelemetry-demo-frontendproxy"
    namespace = "otel-demo"
  }
}