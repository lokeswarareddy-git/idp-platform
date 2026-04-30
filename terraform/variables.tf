variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "environment" {
  description = "Deployment environment (dev | staging | prod)"
  type        = string
  default     = "dev"
}

# ── Networking ─────────────────────────────────────────────────────────────────

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnets" {
  description = "Public subnet IDs for the ALB (min 2 AZs)"
  type        = list(string)
}

variable "private_subnets" {
  description = "Private subnet IDs for ECS tasks (use public subnets + assign_public_ip=true if no NAT gateway)"
  type        = list(string)
}

# ── ECS ────────────────────────────────────────────────────────────────────────

variable "container_image" {
  description = "ECR image for ECS service"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "ecs_cpu" {
  description = "Fargate task CPU units (256 | 512 | 1024 | 2048 | 4096)"
  type        = number
  default     = 256
}

variable "ecs_memory" {
  description = "Fargate task memory in MiB"
  type        = number
  default     = 512
}

variable "ecs_desired_count" {
  description = "Desired number of running ECS tasks"
  type        = number
  default     = 1
}

variable "assign_public_ip" {
  description = "Assign public IP to ECS tasks (required when in public subnets without NAT gateway)"
  type        = bool
  default     = false
}

# ── ALB ────────────────────────────────────────────────────────────────────────

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS. Leave empty for plain HTTP."
  type        = string
  default     = ""
}

# ── Observability ──────────────────────────────────────────────────────────────

variable "alarm_email" {
  description = "Email to receive CloudWatch alarm notifications. Leave empty to skip."
  type        = string
  default     = ""
}
