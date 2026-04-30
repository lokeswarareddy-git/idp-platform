variable "service_name" {
  description = "ECS service name — used to name alarms, SNS topic, and dashboard"
  type        = string
}

variable "cluster_name" {
  description = "ECS cluster name — used for CloudWatch metric dimensions"
  type        = string
}

variable "aws_region" {
  description = "AWS region — used in dashboard log widget"
  type        = string
}

variable "log_group_name" {
  description = "CloudWatch log group name for the ECS service"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix (from aws_lb.arn_suffix) — used for ALB alarms and dashboard"
  type        = string
  default     = ""
}

variable "target_group_arn_suffix" {
  description = "Target group ARN suffix (from aws_lb_target_group.arn_suffix) — used for unhealthy host alarm"
  type        = string
  default     = ""
}

variable "cpu_threshold" {
  description = "CPU utilization % threshold for alarm"
  type        = number
  default     = 80
}

variable "memory_threshold" {
  description = "Memory utilization % threshold for alarm"
  type        = number
  default     = 80
}

variable "http_5xx_threshold" {
  description = "ALB 5xx error count threshold per evaluation period"
  type        = number
  default     = 10
}

variable "alarm_email" {
  description = "Email address for SNS alarm notifications. Leave empty to skip subscription."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}


variable "enable_alb_alarms" {
  description = "Enable ALB CloudWatch alarms"
  type        = bool
  default     = true
}

variable "enable_target_group_alarms" {
  description = "Enable target group alarms"
  type        = bool
  default     = true
}