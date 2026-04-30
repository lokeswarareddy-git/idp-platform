resource "aws_sns_topic" "alarms" {
  name = "${var.service_name}-alarms"
  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  count = var.alarm_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# ---------------------------
# CPU ALARM
# ---------------------------
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.service_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = var.cpu_threshold
  alarm_description   = "ECS CPU utilization above ${var.cpu_threshold}%"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }

  tags = var.tags
}

# ---------------------------
# MEMORY ALARM
# ---------------------------
resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "${var.service_name}-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = var.memory_threshold
  alarm_description   = "ECS memory utilization above ${var.memory_threshold}%"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }

  tags = var.tags
}

# ---------------------------
# ALB 5XX ALARM
# ---------------------------
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  count = var.enable_alb_alarms ? 1 : 0

  alarm_name          = "${var.service_name}-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = var.http_5xx_threshold
  alarm_description   = "ALB 5xx errors above ${var.http_5xx_threshold}"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  tags = var.tags
}

# ---------------------------
# UNHEALTHY HOST ALARM
# ---------------------------
resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  count = var.enable_target_group_alarms ? 1 : 0

  alarm_name          = "${var.service_name}-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "One or more ECS targets are unhealthy"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  tags = var.tags
}

# ---------------------------
# CLOUDWATCH DASHBOARD (FIXED)
# ---------------------------
resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = var.service_name

  dashboard_body = jsonencode({
    widgets = [

      # ---------------- ECS METRICS ----------------
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "ECS CPU & Memory"
          period = 60
          view   = "timeSeries"
          region = var.aws_region
          stat   = "Average"

          metrics = [
            [
              "AWS/ECS", "CPUUtilization",
              "ClusterName", var.cluster_name,
              "ServiceName", var.service_name,
              { "label" = "CPU %" }
            ],
            [
              "AWS/ECS", "MemoryUtilization",
              "ClusterName", var.cluster_name,
              "ServiceName", var.service_name,
              { "label" = "Memory %" }
            ]
          ]
        }
      },

      # ---------------- ALB METRICS ----------------
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "ALB Requests & Errors"
          period = 60
          view   = "timeSeries"
          region = var.aws_region
          stat   = "Sum"

          metrics = [
            [
              "AWS/ApplicationELB", "RequestCount",
              "LoadBalancer", var.alb_arn_suffix,
              { "label" = "Requests" }
            ],
            [
              "AWS/ApplicationELB", "HTTPCode_Target_5XX_Count",
              "LoadBalancer", var.alb_arn_suffix,
              { "label" = "5xx Errors" }
            ]
          ]
        }
      },

      # ---------------- LOGS ----------------
      {
        type   = "log"
        x      = 0
        y      = 6
        width  = 24
        height = 8

        properties = {
          title  = "Application Logs (last 100)"
          query  = "SOURCE '${var.log_group_name}' | fields @timestamp, @message | sort @timestamp desc | limit 100"
          region = var.aws_region
          view   = "table"
        }
      }
    ]
  })
}