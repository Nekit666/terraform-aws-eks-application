output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  value = module.eks.cluster_security_group_id
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if created."
  value       = module.eks.oidc_provider_arn
}

output "cluster_primary_security_group_id" {
  description = "Cluster security group ID created by the EKS module" # Often needed for DB SG rules
  value       = module.eks.cluster_primary_security_group_id
}

# RDS Outputs
# output "db_instance_endpoint" { # Temporarily removed
#   description = "The connection endpoint for the RDS instance"
#   value       = aws_db_instance.default.endpoint
#   sensitive   = true
# }
# 
# output "db_instance_name" { # Temporarily removed
#   description = "The database name"
#   value       = aws_db_instance.default.db_name
# }
# 
# output "db_instance_username" { # Temporarily removed
#   description = "The master username for the database"
#   value       = aws_db_instance.default.username
#   sensitive   = true
# }
# 
# # Note: Password is not output directly for security.
# # It should be passed securely to the application (e.g., via K8s secret created manually or via Secrets Manager).
# output "db_instance_port" { # Temporarily removed
#   description = "The port the database is listening on"
#   value       = aws_db_instance.default.port
# }

# ECR Outputs
# output "backend_ecr_repository_url" { # Temporarily removed
#   description = "URL of the backend ECR repository"
#   value       = aws_ecr_repository.backend.repository_url
# }
# 
# output "frontend_ecr_repository_url" { # Temporarily removed
#   description = "URL of the frontend ECR repository"
#   value       = aws_ecr_repository.frontend.repository_url
# } 