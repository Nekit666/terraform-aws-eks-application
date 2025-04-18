/* # Temporarily commented out RDS resources
# Note: This creates a basic MySQL RDS instance. Review and adjust settings for production.
# Consider using Aurora Serverless v2 for better scaling/cost-effectiveness if applicable.

data "aws_vpc" "selected" {
  id = var.vpc_id
}

# Security Group for RDS allowing traffic from EKS nodes
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow EKS nodes to connect to RDS instance"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow MySQL traffic from EKS Worker Nodes"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    # Reference the security group used by the EKS nodes
    # This assumes the EKS module outputs the node security group ID
    # If using the terraform-aws-modules/eks module v19+, it's node_security_group_id
    security_groups = [module.eks.node_security_group_id]
    # Alternatively, allow from private subnets CIDR blocks:
    # cidr_blocks = var.private_subnets_cidr_blocks # Requires passing CIDR blocks as variable
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-rds-sg"
    Project = var.project_name
  }
}

# RDS Subnet Group (use private subnets)
resource "aws_db_subnet_group" "default" {
  name       = "${var.project_name}-rds-subnet-group"
  subnet_ids = var.private_subnets

  tags = {
    Name    = "${var.project_name}-rds-subnet-group"
    Project = var.project_name
  }
}

# RDS Instance
resource "aws_db_instance" "default" {
  identifier           = "${var.project_name}-db-instance" # Unique identifier
  allocated_storage    = 20 # GB
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0" # Specify desired MySQL version
  instance_class       = "db.t3.micro" # Choose appropriate instance class
  
  db_name              = var.db_name # Database name from variables
  username             = var.db_user # Master username from variables
  password             = var.db_password # Master password from variables

  db_subnet_group_name = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  parameter_group_name = "default.mysql8.0" # Use appropriate default parameter group

  # Backup & Maintenance
  backup_retention_period = 7 # days
  backup_window           = "04:00-06:00" # Choose appropriate window
  maintenance_window      = "sun:06:00-sun:08:00"

  # Security
  publicly_accessible = false
  skip_final_snapshot = true # Set to false for production to take snapshot on deletion

  tags = {
    Name    = "${var.project_name}-db-instance"
    Project = var.project_name
  }
}

# Variables needed (defined in variables.tf):
# vpc_id, private_subnets, db_name, db_user, db_password, project_name
# module.eks.node_security_group_id (output from eks.tf module)
*/ 