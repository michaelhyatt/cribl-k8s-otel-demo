# Install Elastic cluster using ECK
data "http" "elastic_crds" {
  url = "https://download.elastic.co/downloads/eck/2.16.0/crds.yaml"
}

resource "kubectl_manifest" "elastic_crds" {
  for_each = { for i, v in split("---", data.http.elastic_crds.response_body) : i => v }
  yaml_body = each.value
  depends_on = [ null_resource.wait_for_cluster ]
}

data "http" "elastic_operator" {
  url = "https://download.elastic.co/downloads/eck/2.16.0/operator.yaml"
}

resource "kubectl_manifest" "elastic_operator" {
  for_each = { for i, v in split("---", data.http.elastic_operator.response_body) : i => v }
  yaml_body = each.value
  depends_on = [kubectl_manifest.elastic_crds]
}

resource "null_resource" "wait_for_elastic_operator" {
  depends_on = [ null_resource.wait_for_cluster ]

  provisioner "local-exec" {
    command = <<EOF
      while ! kubectl wait --for=condition=Ready pod --selector=control-plane=elastic-operator -n elastic-system --timeout=300s &> /dev/null; do
        echo "Waiting for Elastic Operator to be ready"
        echo ""
        sleep 30
      done
    EOF
  }
  
}

resource "kubectl_manifest" "elastic_license" {
  yaml_body = file("${path.module}/../../elastic/license.yaml")
  depends_on = [null_resource.wait_for_elastic_operator]
}

resource "kubectl_manifest" "elastic_namespace" {
  yaml_body = <<EOF
    apiVersion: v1
    kind: Namespace
    metadata:
      name: elastic
  EOF
  depends_on = [ null_resource.wait_for_elastic_operator ]
}

data "kubectl_file_documents" "elastic_cluster" {
  content = file("${path.module}/../../elastic/elastic.yaml")
}

resource "kubectl_manifest" "elastic_stack" {
  for_each = toset(data.kubectl_file_documents.elastic_cluster.documents)
  yaml_body = each.value
  override_namespace = "elastic"
  depends_on = [kubectl_manifest.elastic_license, kubectl_manifest.elastic_namespace ]
}

data "kubectl_file_documents" "add_dashboard" {
  content = file("${path.module}/../../elastic/add_dashboard.yml")
}

resource "kubectl_manifest" "custom_dashboard" {
  for_each = toset(data.kubectl_file_documents.add_dashboard.documents)
  yaml_body = each.value
  override_namespace = "elastic"
  depends_on = [null_resource.wait_for_kibana_hostname]
}