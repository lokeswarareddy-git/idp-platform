variable "name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "idp-platform"
}

variable "tags" {
  description = "Tags to apply to the ECR repository"
  type        = map(string)
  default     = {}
}
