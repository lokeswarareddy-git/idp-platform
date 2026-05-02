variable "github_org" {
  description = "GitHub organisation or username (e.g. 'lokesh' or 'my-org')"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (e.g. 'idp-platform')"
  type        = string
}

variable "deploy_branch" {
  description = "Branch that is allowed to assume the deploy role"
  type        = string
  default     = "main"
}

variable "role_name" {
  description = "IAM role name for GitHub Actions"
  type        = string
  default     = "github-actions-deploy"
}

variable "ecr_repository_arns" {
  description = "ECR repository ARNs the role may push to"
  type        = list(string)
}

variable "ecs_service_arns" {
  description = "ECS service ARNs the role may update"
  type        = list(string)
}

variable "iam_role_arns" {
  description = "IAM role ARNs the role may pass to ECS (execution + task roles)"
  type        = list(string)
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
