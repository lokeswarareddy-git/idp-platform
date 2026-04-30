variable "name" {
  description = "ALB and target group name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the ALB (min 2 AZs)"
  type        = list(string)
}

variable "target_port" {
  description = "Container port the target group forwards to"
  type        = number
  default     = 8000
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/health"
}

variable "certificate_arn" {
  description = "ACM certificate ARN. Empty string disables HTTPS and uses plain HTTP."
  type        = string
  default     = ""
}

variable "enable_deletion_protection" {
  description = "Prevent accidental ALB deletion"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
