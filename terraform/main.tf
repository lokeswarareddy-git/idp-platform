provider "aws" {
  region = var.aws_region
}

locals {
  name = "idp-platform-${var.environment}"

  tags = {
    Project     = "idp-platform"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ── ECR ────────────────────────────────────────────────────────────────────────
module "ecr" {
  source = "./modules/ecr"
  name   = "idp-platform"
  tags   = local.tags
}

# ── DynamoDB ───────────────────────────────────────────────────────────────────
module "dynamodb" {
  source     = "./modules/dynamodb"
  table_name = "idp-platform-dev"
  hash_key   = "id"

  attributes = [
    {
      name = "id"
      type = "S"
    }
  ]

  tags = local.tags
}

# ── IAM ────────────────────────────────────────────────────────────────────────
module "iam" {
  source              = "./modules/iam"
  service_name        = local.name
  dynamodb_table_arns = [module.dynamodb.table_arn]
  tags                = local.tags
}

# ── ALB ────────────────────────────────────────────────────────────────────────
module "alb" {
  source            = "./modules/alb"
  name              = local.name
  vpc_id            = var.vpc_id
  public_subnet_ids = var.public_subnets
  target_port       = 8000
  health_check_path = "/health"
  certificate_arn   = var.certificate_arn
  tags              = local.tags
}

# ── ECS Fargate ────────────────────────────────────────────────────────────────
module "ecs" {
  source       = "./modules/ecs"
  cluster_name = local.name
  service_name = "idp-platform"
  aws_region   = var.aws_region
  vpc_id       = var.vpc_id

  # ✅ FIXED: use public subnets
  public_subnet_ids = var.public_subnets

  alb_security_group_id = module.alb.security_group_id
  target_group_arn      = module.alb.target_group_arn
  execution_role_arn    = module.iam.execution_role_arn
  task_role_arn         = module.iam.task_role_arn

  container_image = "${module.ecr.repository_url}:latest"
  container_port  = 8000
  cpu             = var.ecs_cpu
  memory          = var.ecs_memory
  desired_count   = var.ecs_desired_count

  assign_public_ip = var.assign_public_ip

  environment_variables = {
    ENVIRONMENT = var.environment
    JSON_LOGS   = "true"
    AWS_REGION  = var.aws_region
  }

  tags = local.tags
}

# ── GitHub Actions OIDC ───────────────────────────────────────────────────────
module "github_oidc" {
  source = "./modules/github_oidc"

  github_org  = var.github_org
  github_repo = var.github_repo

  ecr_repository_arns = [module.ecr.repository_arn]
  ecs_service_arns    = [module.ecs.service_arn]
  iam_role_arns       = [module.iam.execution_role_arn, module.iam.task_role_arn]

  tags = local.tags
}

# ── CloudWatch ────────────────────────────────────────────────────────────────
module "cloudwatch" {
  source = "./modules/cloudwatch"

  service_name   = module.ecs.service_name
  cluster_name   = module.ecs.cluster_name
  aws_region     = var.aws_region
  log_group_name = module.ecs.log_group_name

  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix

  alarm_email = var.alarm_email

  enable_alb_alarms          = true
  enable_target_group_alarms = true

  tags = local.tags
}
