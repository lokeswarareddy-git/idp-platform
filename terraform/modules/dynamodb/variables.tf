variable "table_name" {
  description = "DynamoDB table name"
  type        = string
}

variable "hash_key" {
  description = "Partition key attribute name"
  type        = string
}

variable "range_key" {
  description = "Sort key attribute name (optional)"
  type        = string
  default     = ""
}

variable "attributes" {
  description = "Attribute definitions for keys and GSI keys (S = string, N = number, B = binary)"
  type = list(object({
    name = string
    type = string
  }))
}

variable "global_secondary_indexes" {
  description = "Global secondary index definitions"
  type = list(object({
    name            = string
    hash_key        = string
    range_key       = optional(string)
    projection_type = string
  }))
  default = []
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
