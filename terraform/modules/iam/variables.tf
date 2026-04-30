variable "service_name" {
  description = "Service name used to prefix IAM resource names"
  type        = string
}

variable "dynamodb_table_arns" {
  description = "DynamoDB table ARNs the task role is granted access to"
  type        = list(string)
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
