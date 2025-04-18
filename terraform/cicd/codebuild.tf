# CodeBuild Project for Building Docker images
resource "aws_codebuild_project" "build_project" {
  name          = local.build_project_name
  description   = "Builds Docker images for ${var.project_name}"
  build_timeout = "60" # minutes
  service_role  = aws_iam_role.codebuild_build_role.arn

  artifacts {
    type = "CODEPIPELINE" # Output artifacts to CodePipeline
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0" # Use a standard image with Docker
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true # Required for Docker builds
    image_pull_credentials_type = "CODEBUILD"

    # Pass ECR repo URIs to the build environment (alternative to dynamic lookup in buildspec)
    # environment_variable {
    #   name  = "ECR_BACKEND_REPO_URI"
    #   value = var.backend_ecr_repo_url
    #   type  = "PLAINTEXT"
    # }
    # environment_variable {
    #   name  = "ECR_FRONTEND_REPO_URI"
    #   value = var.frontend_ecr_repo_url
    #   type  = "PLAINTEXT"
    # }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${local.build_project_name}"
      stream_name = "build"
    }
    s3_logs {
      status   = "DISABLED"
    }
  }

  source {
    type            = "CODEPIPELINE"
    buildspec       = "application/buildspec.yml" # Path to buildspec within the source artifact
    # location = # Not needed for CODEPIPELINE source type
  }

  # Enable caching for faster builds (optional)
  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE", "LOCAL_CUSTOM_CACHE"]
  }

  tags = {
    Project = var.project_name
    Purpose = "Docker Image Build"
  }
}

# CodeBuild Project for Deploying to EKS
resource "aws_codebuild_project" "deploy_project" {
  name          = local.deploy_project_name
  description   = "Deploys application to EKS cluster ${var.eks_cluster_name}"
  build_timeout = "15" # minutes
  service_role  = aws_iam_role.codebuild_deploy_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0" # Includes AWS CLI and kubectl
    type                        = "LINUX_CONTAINER"
    privileged_mode             = false # Not usually needed for kubectl commands
    image_pull_credentials_type = "CODEBUILD"
    # Environment variables (like EKS_CLUSTER_NAME) are passed from CodePipeline action config
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${local.deploy_project_name}"
      stream_name = "deploy"
    }
    s3_logs {
      status   = "DISABLED"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-EOF
      version: 0.2
      phases:
        install:
          runtime-versions:
            kubectl: 1.28 # Specify kubectl version compatible with your cluster
          commands:
            - echo "Installing jq..."
            - apt-get update && apt-get install -y jq
        pre_build:
          commands:
            - echo "Configuring kubectl for EKS cluster $EKS_CLUSTER_NAME..."
            - aws eks --region $AWS_DEFAULT_REGION update-kubeconfig --name $EKS_CLUSTER_NAME
            - echo "Verifying kubectl connection..."
            - kubectl version --short
            - kubectl get ns
            # Parse image URIs from the input artifact (imagedefinitions.json)
            - echo "Parsing image definitions from $CODEBUILD_SRC_DIR/imagedefinitions.json"
            - cat $CODEBUILD_SRC_DIR/imagedefinitions.json
            - BACKEND_IMAGE_URI=$(jq -r '.[] | select(.name=="backend-container") | .imageUri' $CODEBUILD_SRC_DIR/imagedefinitions.json)
            - FRONTEND_IMAGE_URI=$(jq -r '.[] | select(.name=="frontend-container") | .imageUri' $CODEBUILD_SRC_DIR/imagedefinitions.json)
            - echo "Backend Image URI: $BACKEND_IMAGE_URI"
            - echo "Frontend Image URI: $FRONTEND_IMAGE_URI"
            - if [ -z "$BACKEND_IMAGE_URI" ] || [ -z "$FRONTEND_IMAGE_URI" ]; then echo "Error: Failed to parse image URIs"; exit 1; fi
        build:
          commands:
            - echo "Deploying application update to EKS cluster $EKS_CLUSTER_NAME..."
            # Option 1: Apply all manifests from source (if they are included)
            # - echo "Applying manifests from k8s/ directory..."
            # - kubectl apply -f $CODEBUILD_SRC_DIR/k8s/ --namespace ${K8S_NAMESPACE:-default}
            
            # Option 2: Set image on existing deployments (requires deployments to exist)
            - echo "Updating backend deployment image..."
            - kubectl set image deployment/backend-deployment backend-container=$BACKEND_IMAGE_URI --namespace ${K8S_NAMESPACE:-default} --record
            - echo "Updating frontend deployment image..."
            - kubectl set image deployment/frontend-deployment frontend-container=$FRONTEND_IMAGE_URI --namespace ${K8S_NAMESPACE:-default} --record
        post_build:
          commands:
            - echo "Checking deployment status..."
            - kubectl rollout status deployment/backend-deployment --namespace ${K8S_NAMESPACE:-default} --timeout=5m
            - kubectl rollout status deployment/frontend-deployment --namespace ${K8S_NAMESPACE:-default} --timeout=5m
            - echo "Deployment completed successfully!"
      EOF
  }

  tags = {
    Project = var.project_name
    Purpose = "EKS Deployment"
  }
} 