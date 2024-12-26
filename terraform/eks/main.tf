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

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.demo_name_prefix}-cluster"
  cluster_version = "1.31"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true

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
