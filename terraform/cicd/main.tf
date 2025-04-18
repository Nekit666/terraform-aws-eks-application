# --- Variables --- (Defined in variables.tf)
# aws_region, project_name, cluster_name
# backend_ecr_repo_url, frontend_ecr_repo_url
# eks_cluster_name, eks_oidc_provider_arn
# codestar_connection_arn (for GitHub/Bitbucket) or codecommit_repo_name

# --- Locals --- 
locals {
  pipeline_name = "${var.project_name}-pipeline"
  build_project_name = "${var.project_name}-build"
  deploy_project_name = "${var.project_name}-deploy"
}

# --- CodeCommit Repository (if using CodeCommit as source) ---
resource "aws_codecommit_repository" "app_repo" {
  # Create repo only if codecommit_repo_name is provided
  count = var.codecommit_repo_name != null ? 1 : 0 

  repository_name = var.codecommit_repo_name
  description     = "Source code repository for ${var.project_name}"

  tags = {
    Project = var.project_name
  }
}

# --- IAM Roles & Policies --- (Defined in iam.tf)

# --- S3 Bucket for Pipeline Artifacts ---
resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = "${var.project_name}-codepipeline-artifacts-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
  # Naming convention to ensure uniqueness

  # Enable versioning for artifact rollback
  versioning {
    enabled = true
  }

  # Lifecycle rule to clean up old artifacts (optional)
  lifecycle_rule {
    id      = "cleanup-old-artifacts"
    enabled = true
    prefix  = "/"
    
    noncurrent_version_expiration {
      days = 30
    }
    expiration {
      days = 90
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Project = var.project_name
    Purpose = "CodePipeline Artifact Store"
  }
}

data "aws_caller_identity" "current" {}

# --- CodeBuild Projects --- (Defined in codebuild.tf)

# --- CodePipeline --- 
resource "aws_codepipeline" "pipeline" {
  name     = local.pipeline_name
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
    type     = "S3"
  }

  # --- Source Stage ---
  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS" # Or "ThirdParty" for GitHub/Bitbucket
      provider         = "CodeCommit" # Change to "GitHub" or "Bitbucket" if needed
      version          = "1"
      output_artifacts = ["SourceOutput"]

      configuration = {
        # For CodeCommit
        RepositoryName = var.codecommit_repo_name # Required if provider is CodeCommit
        BranchName     = var.source_branch_name
        PollForSourceChanges = true # Or use CloudWatch Events/Webhook

        # For GitHub (Version 2)
        # ConnectionArn    = var.codestar_connection_arn # Required if provider is GitHub v2
        # FullRepositoryId = "<YourGitHubUserOrOrg>/<YourRepoName>" # Required
        # BranchName       = var.source_branch_name

        # For Bitbucket
        # ConnectionArn    = var.codestar_connection_arn # Required
        # FullRepositoryId = "<YourBitbucketWorkspace>/<YourRepoName>" # Required
        # BranchName       = var.source_branch_name
      }
    }
  }

  # --- Build Stage ---
  stage {
    name = "Build"
    action {
      name             = "BuildImages"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceOutput"]
      output_artifacts = ["BuildOutput"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.build_project.name
      }
    }
  }

  # --- Deploy Stage ---
  stage {
    name = "DeployToEKS"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["BuildOutput"] # Contains imagedefinitions.json
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.deploy_project.name
        # Pass EKS Cluster Name to deploy project environment
        EnvironmentVariables = jsonencode([
          {
            name  = "EKS_CLUSTER_NAME",
            value = var.eks_cluster_name,
            type  = "PLAINTEXT"
          },
          {
            name  = "K8S_NAMESPACE", # Optional: specify namespace
            value = "default", 
            type  = "PLAINTEXT"
          }
          # Add other env vars if needed by deploy buildspec
        ])
      }
    }
  }

  tags = {
    Project = var.project_name
  }
} 