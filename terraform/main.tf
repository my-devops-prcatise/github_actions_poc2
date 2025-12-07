
#################################
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

  # IAM Roles for Service Accounts (recommended)
  enable_irsa = true

  # ✅ Fargate profiles (no EC2 nodes)
  fargate_profiles = {
    default = {
      name = "fp-default"
      selectors = [
        { namespace = "default" },
        { namespace = "kube-system" }
      ]
    }
  }

  # ✅ Create CloudWatch log group for control-plane logs
  create_cloudwatch_log_group = true
  # Optional: set retention (default is "forever")
  cloudwatch_log_group_retention_in_days = 30

  # Optional: enable specific control plane log types
  cluster_log_types = ["api", "audit", "scheduler", "controllerManager"]

  tags = {
    Name = var.cluster_name
  }
}
