variable "aws_region" {}
variable "project_name" {}
variable "cluster_name" {}
variable "domain_name" {}
variable "hosted_zone_id" {}
variable "vpc_id" {}
variable "private_subnets" {}
variable "public_subnets" {}
variable "use_domain_name" {
  description = "Whether to use the domain name for the application"
  type        = bool
  default     = false
}

# variable "db_name" { # Temporarily removed
#   description = "Database name for RDS"
#   type        = string
# }
# 
# variable "db_user" { # Temporarily removed
#   description = "Master username for RDS"
#   type        = string
#   sensitive = true
# }
# 
# variable "db_password" { # Temporarily removed
#   description = "Master password for RDS"
#   type        = string
#   sensitive = true
# }

# variable "codebuild_deploy_role_arn" { # Temporarily removed
#   description = "ARN of the IAM role for CodeBuild deploy stage to map in aws-auth"
#   type        = string
# } 