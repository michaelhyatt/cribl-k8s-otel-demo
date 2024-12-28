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

# Install otel-demo app
locals {
  otel_demo_manifests = [for manifest in split("---", file("${path.module}/../../otel-demo/opentelemetry-demo.yaml")) : yamldecode(manifest)]
  elastic_manifests = [for manifest in split("---", file("${path.module}/../../elastic/elastic.yaml")) : yamldecode(manifest)]
  elastic_dashboard = [for manifest in split("---", file("${path.module}/../../elastic/add_dashboard.yml")) : yamldecode(manifest)]
}

resource "kubectl_manifest" "opentelemetry_demo" {
  for_each = { for i, v in local.otel_demo_manifests : i => v }
  yaml_body = yamlencode(merge(each.value, { "metadata" = merge(each.value.metadata, { "namespace" = "otel-demo" }) }))

  force_conflicts = true
}

# Install Elastic cluster using ECK
data "http" "elastic_crds" {
  url = "https://download.elastic.co/downloads/eck/2.16.0/crds.yaml"
}

resource "kubectl_manifest" "elastic_crds" {
  for_each = { for i, v in split("---", data.http.elastic_crds.response_body) : i => v }
  yaml_body = each.value
}

data "http" "elastic_operator" {
  url = "https://download.elastic.co/downloads/eck/2.16.0/operator.yaml"
}

resource "kubectl_manifest" "elastic_operator" {
  for_each = { for i, v in split("---", data.http.elastic_operator.response_body) : i => v }
  yaml_body = each.value
  wait_for_rollout = true
  depends_on = [kubectl_manifest.elastic_crds]
}

resource "kubectl_manifest" "elastic_license" {
  yaml_body = file("${path.module}/../../elastic/license.yaml")
  depends_on = [kubectl_manifest.elastic_operator]
}

resource "kubectl_manifest" "elastic_namespace" {
  yaml_body = <<EOF
    apiVersion: v1
    kind: Namespace
    metadata:
      name: elastic
  EOF
}

resource "kubectl_manifest" "elastic_stack" {
  for_each = { for i, v in local.elastic_manifests : i => v }
  yaml_body = yamlencode(merge(each.value, { "metadata" = merge(each.value.metadata, { "namespace" = "elastic" }) }))

  force_conflicts = true
  depends_on = [kubectl_manifest.elastic_license, kubectl_manifest.elastic_namespace, kubectl_manifest.elastic_operator]
}

resource "kubectl_manifest" "custom_dashboard" {
  for_each = { for i, v in local.elastic_dashboard : i => v }
  yaml_body = yamlencode(merge(each.value, { "metadata" = merge(each.value.metadata, { "namespace" = "elastic" }) }))

  force_conflicts = true
  depends_on = [kubectl_manifest.elastic_stack]
}