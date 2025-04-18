module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0" # Use a specific minor version

  cluster_name    = "${var.project_name}-${var.cluster_name}"
  cluster_version = "1.28" # Specify your desired K8s version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets # Deploy nodes in private subnets

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64" # Amazon Linux 2
  }

  eks_managed_node_groups = {
    # General purpose nodes
    general = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

      labels = {
        role = "general"
      }

      tags = {
        Name = "${var.project_name}-${var.cluster_name}-general-nodes"
      }
    }
    # Add more node groups if needed (e.g., for specific workloads)
  }

  # Enable cluster OIDC provider for IAM Roles for Service Accounts (IRSA)
  enable_irsa = true

  # Manage the aws-auth configmap
  manage_aws_auth_configmap = true

  # Add CodeBuild Deploy Role ARN to aws-auth ConfigMap
  aws_auth_roles = [ # Temporarily empty, CodeBuild role mapping removed
    # {
    #   rolearn  = var.codebuild_deploy_role_arn # Pass this ARN from the CICD module
    #   username = "codebuild-deployer"
    #   groups   = ["system:masters"] # Grant admin privileges, review/restrict as needed
    # },
    # Add other roles if needed
  ]

  # Map EKS managed node group role automatically (default behavior)
  # map_roles = [] # Default is usually sufficient unless specific mapping is needed

  # Map additional users if needed
  # aws_auth_users = [
  #   {
  #     userarn  = "arn:aws:iam::ACCOUNT_ID:user/your-admin-user"
  #     username = "your-admin-user"
  #     groups   = ["system:masters"]
  #   },
  # ]

  # Cluster Addons (optional, but recommended)
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  # Control plane logging (optional)
  # cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = {
    Environment = "dev"
    Project     = var.project_name
  }
} 