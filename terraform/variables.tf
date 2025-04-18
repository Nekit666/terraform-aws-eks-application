variable "aws_region" {
  description = "AWS region to deploy the infrastructure"
  type        = string
  default     = "us-east-1" # Change if needed
}

variable "project_name" {
  description = "Project name to use as a base for all resources"
  type        = string
  default     = "justeasylearn"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-cluster"
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "justeasylearn.com"
}

variable "hosted_zone_id" {
  description = "Route 53 Hosted Zone ID for the domain_name"
  type        = string
  default     = ""
  # IMPORTANT: You MUST provide the correct Hosted Zone ID for your domain here
  # You can find this in the AWS Route 53 console for 'justeasylearn.com'
}

variable "use_domain_name" {
  description = "Whether to use the domain name for the application. Set to false to use the ALB DNS name directly."
  type        = bool
  default     = false
}

variable "create_new_vpc" {
  description = "Whether to create a new VPC (true) or use an existing one (false)"
  type        = bool
  default     = false
}

variable "existing_vpc_id" {
  description = "ID of existing VPC to use if create_new_vpc is false"
  type        = string
  default     = ""
}

variable "existing_private_subnet_ids" {
  description = "List of existing private subnet IDs to use if create_new_vpc is false"
  type        = list(string)
  default     = []
}

variable "existing_public_subnet_ids" {
  description = "List of existing public subnet IDs to use if create_new_vpc is false"
  type        = list(string)
  default     = []
}

# variable "db_user" { # Temporarily removed
#   description = "Database username"
#   type        = string
#   sensitive   = true
#   # Provide via TF_VAR_db_user environment variable or terraform.tfvars
# }
# 
# variable "db_password" { # Temporarily removed
#   description = "Database password"
#   type        = string
#   sensitive   = true
#   # Provide via TF_VAR_db_password environment variable or terraform.tfvars
# }
# 
# variable "db_name" { # Temporarily removed
#   description = "Database name"
#   type        = string
#   default     = "mydatabase"
# }
# 
# variable "db_host" { # Temporarily removed (as RDS is not created here)
#   description = "Database host endpoint (will be output from RDS module if used)"
#   type        = string
#   default     = "rds-endpoint.example.com" # Placeholder, replace if not creating RDS via Terraform
# } 