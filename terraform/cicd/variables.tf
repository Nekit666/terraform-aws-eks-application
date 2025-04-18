variable "aws_region" {
  description = "AWS region for the CICD resources"
  type        = string
}

variable "project_name" {
  description = "Name of the project (used for naming resources)"
  type        = string
}

variable "eks_cluster_name" {
  description = "Name of the target EKS cluster for deployment"
  type        = string
}

variable "eks_oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider for IAM Roles for Service Accounts (if using IRSA for deploy role)"
  type        = string
  default     = null # Optional, only needed if deploy role uses IRSA
}

# --- Source Configuration ---
variable "source_branch_name" {
  description = "Branch to trigger the pipeline from"
  type        = string
  default     = "main"
}

variable "codecommit_repo_name" {
  description = "Name of the AWS CodeCommit repository (required if source provider is CodeCommit)"
  type        = string
  default     = null # Set this if using CodeCommit
}

variable "codestar_connection_arn" {
  description = "ARN of the AWS CodeStar connection (required for GitHub/Bitbucket)"
  type        = string
  default     = null # Set this if using GitHub/Bitbucket
}

# --- ECR URIs (passed from eks-cluster module or root) ---
variable "backend_ecr_repo_url" {
  description = "URL of the backend ECR repository"
  type        = string
}

variable "frontend_ecr_repo_url" {
  description = "URL of the frontend ECR repository"
  type        = string
} 