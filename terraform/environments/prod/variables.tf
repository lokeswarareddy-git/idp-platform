variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the ALB (min 2 AZs)"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS (required in prod)"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag to deploy (use a specific SHA or semver, not 'latest')"
  type        = string
}
