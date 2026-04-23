output "cribl_worker_external_url" {
  description = "URL to access the Cribl Worker for Search replays"
  value = try(format("Cribl Worker URL: http://%s:10200", data.kubernetes_service.cribl_worker_service.status.0.load_balancer.0.ingress.0.hostname), "Cribl Worker URL: not yet available")
}

output "kibana_external_url" {
  description = "URL to access Kibana"
  value = try(format("Kibana URL: http://%s:5601", data.kubernetes_service.kibana_service.status.0.load_balancer.0.ingress.0.hostname), "Kibana URL: not yet available")
}

output "app_external_url" {
  description = "URL to access the otel-demo app and loadgen (/loadgen/) UI"
  value = try(format("otel-demo App URL: http://%s:8080", data.kubernetes_service.app_service.status.0.load_balancer.0.ingress.0.hostname), "otel-demo App URL: not yet available")
}

output "cluster_name" {
  description = "EKS Cluster Name"
  value       = module.eks.cluster_name
}

output "region" {
  description = "AWS Region"
  value       = var.region
}