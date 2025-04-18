terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.9"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}

# Create a new VPC only if create_new_vpc is true
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.3"
  
  count = var.create_new_vpc ? 1 : 0

  name = "${var.project_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true # Use a single NAT Gateway for cost savings in non-prod

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.project_name}-${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.project_name}-${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }

  tags = {
    Environment = "dev"
    Project     = var.project_name
  }
}

# Local values to simplify VPC and subnet references
locals {
  vpc_id = var.create_new_vpc ? module.vpc[0].vpc_id : var.existing_vpc_id
  private_subnets = var.create_new_vpc ? module.vpc[0].private_subnets : var.existing_private_subnet_ids
  public_subnets = var.create_new_vpc ? module.vpc[0].public_subnets : var.existing_public_subnet_ids
}

# Call the EKS cluster module
module "eks_cluster" {
  source           = "./eks-cluster"
  project_name     = var.project_name
  aws_region       = var.aws_region
  cluster_name     = "eks-cluster"
  vpc_id           = local.vpc_id
  private_subnets  = local.private_subnets
  public_subnets   = local.public_subnets
  domain_name       = var.domain_name
  hosted_zone_id    = var.hosted_zone_id
  use_domain_name   = var.use_domain_name
}

# Call the CICD Pipeline module
# module "cicd" { # Temporarily commented out
#   source = "./cicd"
# 
#   aws_region       = var.aws_region
#   project_name     = var.project_name
#   eks_cluster_name = module.eks_cluster.cluster_name # Get cluster name from EKS module output
# 
#   # Pass ECR repo URLs from the EKS module outputs (assuming ecr.tf is in eks-cluster module)
#   backend_ecr_repo_url  = module.eks_cluster.backend_ecr_repository_url
#   frontend_ecr_repo_url = module.eks_cluster.frontend_ecr_repository_url
# 
#   # --- Source Configuration ---
#   # You MUST configure one of the following source types:
# 
#   # Option 1: CodeCommit
#   codecommit_repo_name = "justeasylearn-repo" # Replace with your CodeCommit repo name
#   source_branch_name   = "main" # Or your development branch
# 
#   # Option 2: GitHub / Bitbucket (Requires CodeStar Connection setup in AWS Console)
#   # codestar_connection_arn = "arn:aws:codestar-connections:REGION:ACCOUNT_ID:connection/YOUR_CONNECTION_ID" # Replace with your connection ARN
#   # # You also need to provide FullRepositoryId in terraform/cicd/main.tf under the source stage configuration
# 
#   # Optional: Pass OIDC provider ARN if using IRSA for deploy role
#   # eks_oidc_provider_arn = module.eks_cluster.oidc_provider_arn
# } 