# The provisioning is done in other files, this file is used to retrieve the external IPs of the services
# Install kubectl provider
terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14.0"
    }
  }
}

provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    command     = "aws"
  }
}

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

resource "null_resource" "wait_for_stream_hostname" {
  depends_on = [ null_resource.update_kubeconfig ]

  provisioner "local-exec" {
    command = <<EOT
      while ! kubectl get service cribl-worker-logstream-workergroup -n cribl -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' &> /dev/null; do
      sleep 30 
      done
    EOT
  }
}

data "kubernetes_service" "cribl_worker_service" {
  metadata {
    name      = "cribl-worker-logstream-workergroup"
    namespace = "cribl"
  }
  depends_on = [ null_resource.wait_for_stream_hostname ]
}

resource "null_resource" "wait_for_kibana_hostname" {
  depends_on = [ null_resource.update_kubeconfig ]

  provisioner "local-exec" {
    command = <<EOT
      while ! kubectl get service kibana-kb-http -n elastic -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' &> /dev/null; do
      sleep 30 
      done
    EOT
  }
}

data "kubernetes_service" "kibana_service" {
  depends_on = [ null_resource.wait_for_kibana_hostname ]

  metadata {
    name      = "kibana-kb-http"
    namespace = "elastic"
  }
}

resource "null_resource" "wait_for_app_hostname" {
  depends_on = [ null_resource.update_kubeconfig ]

  provisioner "local-exec" {
    command = <<EOT
      while ! kubectl get service opentelemetry-demo-frontendproxy -n otel-demo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' &> /dev/null; do
      sleep 30 
      done
    EOT
  }
}

data "kubernetes_service" "app_service" {
  metadata {
    name      = "opentelemetry-demo-frontendproxy"
    namespace = "otel-demo"
  }
  depends_on = [ null_resource.wait_for_app_hostname ]
}