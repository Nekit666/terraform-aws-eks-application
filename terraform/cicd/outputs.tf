output "codebuild_deploy_role_arn" {
  description = "ARN of the IAM role used by the CodeBuild deploy project"
  value       = aws_iam_role.codebuild_deploy_role.arn
}

output "codecommit_repository_clone_url_http" {
  description = "Clone URL for the CodeCommit repository (HTTPS)"
  value       = aws_codecommit_repository.app_repo.clone_url_http
  # Only available if CodeCommit repo is created
} 