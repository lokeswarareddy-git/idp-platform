output "dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.this.dns_name
}

output "zone_id" {
  description = "ALB canonical hosted zone ID (for Route 53 alias records)"
  value       = aws_lb.this.zone_id
}

output "arn" {
  description = "ALB ARN"
  value       = aws_lb.this.arn
}

output "target_group_arn" {
  description = "Target group ARN"
  value       = aws_lb_target_group.this.arn
}

output "security_group_id" {
  description = "ALB security group ID"
  value       = aws_security_group.this.id
}
