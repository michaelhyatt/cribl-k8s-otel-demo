# Update it to the correct region
variable "region" {
  description = "AWS region to deploy the cluster in"
  default = "us-west-2"
}

variable "demo_name_prefix" {
  description = "Give it a name we can recognise in AWS EC2 console"
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
    "kubernetes.io/cluster/${var.demo_name_prefix}" = "shared"
    "kubernetes.io/role/internal-elb"       = "1"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.demo_name_prefix}" = "shared"
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
    instance_types         = ["t3.medium"]
    vpc_security_group_ids = [aws_security_group.eks-sg.id]
  }

  eks_managed_node_groups = {
    node_group = {
      min_size     = 2
      max_size     = 2
      desired_size = 2
    }
  }

  tags = {
    Environment = "${var.demo_name_prefix}"
    Terraform   = "true"
  }
}

output "cluster_id" {
  description = "AWS EKS Cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_name" {
  description = "AWS EKS Cluster ID"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "AWS EKS Cluster Endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID of the control plane in the cluster"
  value       = module.eks.cluster_security_group_id
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}