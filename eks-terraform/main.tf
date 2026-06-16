terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# -------------------------
# VPC
# -------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

  enable_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/hello-eks-cluster" = "shared"
  }
}

# -------------------------
# EKS CLUSTER
# -------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.0.0"

  cluster_name    = "hello-eks-cluster"
  cluster_version = "1.28"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true

  # -------------------------
  # NODE GROUP (Auto Scaling 1 → 4)
  # -------------------------
  eks_managed_node_groups = {
    workers = {
      instance_types = ["t3.small"]
      ami_type       = "AL2_x86_64"

      min_size     = 1
      desired_size = 1
      max_size     = 4

      labels = {
        role = "worker"
      }

      update_config = {
        max_unavailable = 1
      }
    }
  }
}

# -------------------------
# OIDC (Required for ALB + IRSA)
# -------------------------
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

module "oidc" {
  source  = "terraform-aws-modules/eks/aws//modules/oidc-provider"
  cluster_name = module.eks.cluster_name
}

# -------------------------
# IAM ROLE FOR ALB CONTROLLER (IRSA)
# -------------------------
module "alb_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "alb-controller-role"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.oidc.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

# -------------------------
# REQUIRED EKS ADD-ONS
# -------------------------
resource "aws_eks_addon" "coredns" {
  cluster_name = module.eks.cluster_name
  addon_name   = "coredns"
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = module.eks.cluster_name
  addon_name   = "vpc-cni"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = module.eks.cluster_name
  addon_name   = "kube-proxy"
}