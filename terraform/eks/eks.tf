provider "aws" {
  region = var.region
}

data "aws_availability_zones" "azs" {}

# Create a VPC to deploy the EKS cluster into
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

# Create a security group for the EKS cluster
resource "aws_security_group" "eks-sg" {
  name   = "${var.demo_name_prefix}-eks-sg"
  vpc_id = module.vpc.vpc_id
}

# Allow inbound and outbound traffic to the EKS cluster
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

# Create the EKS cluster
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

# Update kubeconfig to use the new EKS cluster
resource "null_resource" "update_kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks --region ${var.region} update-kubeconfig --name ${module.eks.cluster_name} --alias eks" 
  }

  depends_on = [module.eks.cluster_name]
}

# Wait for the EKS cluster to be ready
resource "null_resource" "wait_for_cluster" {
  provisioner "local-exec" {
    command = <<EOT
        while ! kubectl wait --for=condition=Ready node --all --timeout=20m &> /dev/null; do
          echo "Waiting for EKS cluster to be ready"
          echo ""
          sleep 10
        done
    EOT
  }

  depends_on = [null_resource.update_kubeconfig]
}