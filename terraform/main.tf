provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0" # or "~> 5.0"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"#################################
# Provider configuration
#################################
provider "aws" {
  region = var.region
}

#################################
# VPC module
#################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0" # or "~> 5.0"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway = true

  tags = {
    Name = "eks-vpc"
  }
}

#################################
# EKS module (Fargate only)
#################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.10.1" # or "~> 21.0"

  # Cluster details
  name               = var.cluster_name
  kubernetes_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # IRSA is nice to have
  enable_irsa = true

  # ❌ REMOVE EC2 managed node groups (t3.medium / Free Tier issue)
  # eks_managed_node_groups = {
  #   default = {
  #     min_size     = 1
  #     max_size     = 3
  #     desired_size = 2
  #
  #     instance_types = ["t3.medium"]
  #     capacity_type  = "ON_DEMAND"
  #   }
  # }

  # ✅ Use Fargate profiles instead
  fargate_profiles = {
    default = {
      name = "fp-default"

      # Any pod in these namespaces will run on Fargate
      selectors = [
        {
          namespace = "default"
        },
        {
          namespace = "kube-system"
        }
      ]
    }
  }

  # ✅ Avoid "log group already exists" error
  create_cloudwatch_log_group = false

  tags = {
    Name = var.cluster_name
  }
}


  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway = true
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.10.1" # or "~> 21.0"

  # Uses variable from variable.tf
  name               = var.cluster_name
  kubernetes_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # EKS managed node group
  eks_managed_node_groups = {
    default = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
    }
  }
}

