# Install otel-demo app
data "kubectl_file_documents" "otel_demo_manifests" {
  content = file("${path.module}/../../otel-demo/opentelemetry-demo.yaml")
}

resource "kubectl_manifest" "opentelemetry_demo" {
  for_each  = toset(data.kubectl_file_documents.otel_demo_manifests.documents)
  yaml_body = each.value
  override_namespace = "otel-demo"
  depends_on = [ null_resource.wait_for_cluster ]
}