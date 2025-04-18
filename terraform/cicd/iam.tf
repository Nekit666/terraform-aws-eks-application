# IAM Role for CodePipeline
data "aws_iam_policy_document" "codepipeline_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "${var.project_name}-codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_role.json

  tags = {
    Project = var.project_name
  }
}

data "aws_iam_policy_document" "codepipeline_policy" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.codepipeline_artifacts.arn,
      "${aws_s3_bucket.codepipeline_artifacts.arn}/*"
    ]
  }
  statement {
    actions = [
      "codecommit:GetBranch",
      "codecommit:GetCommit",
      "codecommit:UploadArchive",
      "codecommit:GetUploadArchiveStatus",
      "codecommit:CancelUploadArchive",
      "codecommit:GetRepository"
      # Add ListBranches if needed
    ]
    # Adjust resource ARN if using CodeCommit
    resources = ["arn:aws:codecommit:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${var.codecommit_repo_name}"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceProvider"
      values   = ["codepipeline.amazonaws.com"]
    }
  }
  statement {
    actions = [
      "codestar-connections:UseConnection" # Required for GitHub/Bitbucket
    ]
    resources = [var.codestar_connection_arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceProvider"
      values   = ["codepipeline.amazonaws.com"]
    }
  }
  statement {
    actions = [
      "codebuild:StartBuild",
      "codebuild:StopBuild",
      "codebuild:BatchGetBuilds"
    ]
    resources = [
      aws_codebuild_project.build_project.arn,
      aws_codebuild_project.deploy_project.arn
    ]
  }
  statement {
    actions = [
      "iam:PassRole", # Allows CodePipeline to pass the CodeBuild roles
    ]
    resources = [
      aws_iam_role.codebuild_build_role.arn,
      aws_iam_role.codebuild_deploy_role.arn
    ]
    condition {
      test     = "StringEqualsIfExists"
      variable = "iam:AssociatedResourceArn"
      values = [
        aws_codepipeline.pipeline.arn
      ]
    }
  }
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "${var.project_name}-codepipeline-policy"
  role   = aws_iam_role.codepipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}

# IAM Role for CodeBuild Build Project
data "aws_iam_policy_document" "codebuild_build_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codebuild_build_role" {
  name               = "${var.project_name}-codebuild-build-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_build_assume_role.json

  tags = {
    Project = var.project_name
  }
}

data "aws_iam_policy_document" "codebuild_build_policy" {
  # Permissions for CodeBuild service interactions (logs, reports)
  statement {
    effect = "Allow"
    actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${local.build_project_name}",
      "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${local.build_project_name}:*",
    ]
  }
  # Permissions for S3 artifacts access
  statement {
    effect    = "Allow"
    actions   = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketAcl",
        "s3:GetBucketLocation",
        "s3:ListBucket"
    ]
    resources = [
        aws_s3_bucket.codepipeline_artifacts.arn,
        "${aws_s3_bucket.codepipeline_artifacts.arn}/*"
    ]
  }
  # Permissions for ECR
  statement {
    effect  = "Allow"
    actions = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetRepositoryPolicy",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:DescribeImages",
        "ecr:BatchGetImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage"
    ]
    resources = [ # Grant access to the specific ECR repos
        "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${var.project_name}/backend",
        "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${var.project_name}/frontend"
    ]
  }
  statement {
     # Grant ECR GetAuthorizationToken access more broadly as required
    effect = "Allow"
    actions = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  # Permissions for calling STS GetCallerIdentity (used in buildspec)
   statement {
    effect = "Allow"
    actions = ["sts:GetCallerIdentity"]
    resources = ["*"] 
  }
  # Permissions for SSM Parameter Store (if used in buildspec)
  # statement {
  #   effect = "Allow"
  #   actions = ["ssm:GetParameters"]
  #   resources = ["arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/myapplication/*"] # Adjust path as needed
  # }
}

resource "aws_iam_role_policy" "codebuild_build_policy" {
  name   = "${var.project_name}-codebuild-build-policy"
  role   = aws_iam_role.codebuild_build_role.id
  policy = data.aws_iam_policy_document.codebuild_build_policy.json
}

# IAM Role for CodeBuild Deploy Project
data "aws_iam_policy_document" "codebuild_deploy_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codebuild_deploy_role" {
  name               = "${var.project_name}-codebuild-deploy-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_deploy_assume_role.json

  tags = {
    Project = var.project_name
  }
}

data "aws_iam_policy_document" "codebuild_deploy_policy" {
  # Basic CodeBuild permissions (logs, S3 artifacts)
  statement {
    effect = "Allow"
    actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${local.deploy_project_name}",
      "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${local.deploy_project_name}:*",
    ]
  }
  statement {
    effect    = "Allow"
    actions   = [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketAcl",
        "s3:GetBucketLocation",
        "s3:ListBucket"
    ]
    resources = [
        aws_s3_bucket.codepipeline_artifacts.arn,
        "${aws_s3_bucket.codepipeline_artifacts.arn}/*"
    ]
  }

  # Permissions to interact with the EKS Cluster
  statement {
    effect = "Allow"
    actions = [
      "eks:DescribeCluster" # Allows CodeBuild to get cluster endpoint and CA
    ]
    resources = [
      # Reference the EKS cluster ARN (you might need to pass this as a variable or construct it)
      "arn:aws:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${var.eks_cluster_name}"
    ]
  }
  # Add other permissions needed by kubectl, e.g., if managing namespaces, secrets, etc.
  # IMPORTANT: This role needs to be mapped in the aws-auth ConfigMap in EKS
  # for kubectl commands to work. Terraform can manage this ConfigMap.
}

resource "aws_iam_role_policy" "codebuild_deploy_policy" {
  name   = "${var.project_name}-codebuild-deploy-policy"
  role   = aws_iam_role.codebuild_deploy_role.id
  policy = data.aws_iam_policy_document.codebuild_deploy_policy.json
} 