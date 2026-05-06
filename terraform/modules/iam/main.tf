data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Used by ECS control plane: pull images from ECR, write logs to CloudWatch
resource "aws_iam_role" "execution" {
  name               = "${var.service_name}-ecs-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Used by the application container at runtime
resource "aws_iam_role" "task" {
  name               = "${var.service_name}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "task_dynamodb" {
  statement {
    sid    = "DynamoDBAccess"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
    ]
    resources = var.dynamodb_table_arns
  }
}

resource "aws_iam_policy" "task_dynamodb" {
  name   = "${var.service_name}-dynamodb"
  policy = data.aws_iam_policy_document.task_dynamodb.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "task_dynamodb" {
  role       = aws_iam_role.task.name
  policy_arn = aws_iam_policy.task_dynamodb.arn
}

data "aws_iam_policy_document" "task_provisioning" {
  statement {
    sid       = "STSIdentity"
    effect    = "Allow"
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }

  statement {
    sid    = "S3Provisioning"
    effect = "Allow"
    actions = [
      "s3:CreateBucket",
      "s3:PutBucketVersioning",
      "s3:PutBucketTagging",
      "s3:PutBucketPublicAccessBlock",
    ]
    resources = ["arn:aws:s3:::*"]
  }

  statement {
    sid    = "DynamoDBProvisioning"
    effect = "Allow"
    actions = [
      "dynamodb:CreateTable",
      "dynamodb:TagResource",
      "dynamodb:DescribeTable",
    ]
    resources = ["arn:aws:dynamodb:*:*:table/*"]
  }
}

resource "aws_iam_policy" "task_provisioning" {
  name   = "${var.service_name}-provisioning"
  policy = data.aws_iam_policy_document.task_provisioning.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "task_provisioning" {
  role       = aws_iam_role.task.name
  policy_arn = aws_iam_policy.task_provisioning.arn
}
