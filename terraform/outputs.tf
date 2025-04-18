output "vpc_id" {
  description = "The ID of the VPC"
  value       = local.vpc_id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = local.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = local.public_subnets
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks_cluster.cluster_endpoint
}

output "eks_cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane."
  value       = module.eks_cluster.cluster_security_group_id
}

output "eks_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "eks_cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks_cluster.cluster_name
}

# # To configure kubectl locally:
# aws eks --region $(terraform output -raw eks_region) update-kubeconfig --name $(terraform output -raw eks_cluster_name) 