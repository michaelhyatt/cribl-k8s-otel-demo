# Install Helm
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
      command     = "aws"
    }
  }
}

# Install Cribl Stream
resource "helm_release" "cribl_worker" {
  
  name       = "cribl-worker"
  repository = "https://criblio.github.io/helm-charts/"
  chart      = "logstream-workergroup"
  version    = "${var.cribl_stream_version}"
  namespace  = "cribl"
  create_namespace = true

  depends_on = [null_resource.update_kubeconfig]

  set {
    name  = "config.host"
    value = "${var.cribl_stream_leader_url}"
  }

  set {
    name  = "config.token"
    value = "${var.cribl_stream_token}"
  }

  set {
    name  = "config.group"
    value = "${var.cribl_stream_worker_group}"
  }

  set {
    name  = "config.tlsLeader.enable"
    value = "true"
  }

  set {
    name  = "env.CRIBL_K8S_TLS_REJECT_UNAUTHORIZED"
    value = "0"
  }

  set {
    name  = "env.CRIBL_MAX_WORKERS"
    value = "4"
  }

  values = [ file("${path.module}/../../cribl/stream/values.yaml") ]
}

# Install Cribl Edge
resource "helm_release" "edge" {
  
  name       = "cribl-edge"
  repository = "https://criblio.github.io/helm-charts/"
  chart      = "edge"
  version    = "${var.cribl_edge_version}"
  namespace  = "cribl"
  create_namespace = true

  depends_on = [null_resource.update_kubeconfig]

  set {
    name  = "cribl.leader"
    value = "tls://${var.cribl_edge_token}@${var.cribl_edge_leader_url}?group=${var.cribl_edge_fleet}"
  }

  set {
    name  = "env.CRIBL_K8S_TLS_REJECT_UNAUTHORIZED"
    value = "0"
  }

  values = [ file("${path.module}/../../cribl/edge/values.yaml") ]
}