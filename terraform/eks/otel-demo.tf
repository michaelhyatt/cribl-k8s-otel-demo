# Install otel-demo app
resource "kubectl_manifest" "opentelemetry_demo" {
  for_each = { for i, v in local.otel_demo_manifests : i => v }
  yaml_body = yamlencode(merge(each.value, { "metadata" = merge(each.value.metadata, { "namespace" = "otel-demo" }) }))
  wait_for_rollout = true
  depends_on = [ null_resource.wait_for_cluster ]
}