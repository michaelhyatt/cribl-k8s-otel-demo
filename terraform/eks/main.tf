# Update it to the correct region
variable "region" {
  description = "AWS region to deploy the cluster in"
  default = "us-west-2"
}

variable "demo_name_prefix" {
  description = "Give it a name we can recognise in AWS EC2 console"
}

variable "cribl_edge_leader_url" {
  description = "The leader URL for the Cribl Edge"
}

variable "cribl_edge_token" {
  description = "The token for the Cribl Edge"
}

variable "cribl_edge_version" {
  description = "The version of the Cribl Edge"
}

variable "cribl_edge_fleet" {
  description = "The fleet name for the Cribl Edge"
}

variable "cribl_stream_leader_url" {
  description = "The leader URL for the Cribl Stream"
}

variable "cribl_stream_token" {
  description = "The token for the Cribl Stream"
}

variable "cribl_stream_version" {
  description = "The version of the Cribl Stream"
}

variable "cribl_stream_worker_group" {
  description = "The worker group for the Cribl Stream"
}

provider "aws" {
  region = var.region
}

data "aws_availability_zones" "azs" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.demo_name_prefix}-vpc"
  cidr = "10.0.0.0/16"

  azs             = data.aws_availability_zones.azs.names
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.demo_name_prefix}-cluster" = "shared"
    "kubernetes.io/role/internal-elb"       = "1"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.demo_name_prefix}-cluster" = "shared"
    "kubernetes.io/role/elb"                = "1"
  }
}

resource "aws_security_group" "eks-sg" {
  name   = "${var.demo_name_prefix}-eks-sg"
  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group_rule" "eks-sg-ingress" {
  description       = "allow inbound traffic from eks"
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  security_group_id = aws_security_group.eks-sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "eks-sg-egress" {
  description       = "allow outbound traffic to eks"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  security_group_id = aws_security_group.eks-sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.demo_name_prefix}-cluster"
  cluster_version = "1.31"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true


  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    ami_type               = "AL2_x86_64"
    instance_types         = ["c5.xlarge"]
    vpc_security_group_ids = [aws_security_group.eks-sg.id]
    volume_size            = 50  
    volume_type            = "gp2"
  }

  eks_managed_node_groups = {
    node_group = {
      min_size     = 3
      max_size     = 3
      desired_size = 3
    }
  }

  tags = {
    Environment = "${var.demo_name_prefix}"
    Terraform   = "true"
  }
}

resource "null_resource" "update_kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks --region ${var.region} update-kubeconfig --name ${module.eks.cluster_name}"
  }

  depends_on = [module.eks]
}

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