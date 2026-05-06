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

# ECR is shared across environments — reference existing repository
data "aws_ecr_repository" "app" {
  name = "idp-platform"
}

module "dynamodb" {
  source     = "../../modules/dynamodb"
  table_name = local.name
  hash_key   = "id"
  attributes = [
    { name = "id", type = "S" }
  ]
  tags = local.tags
}

module "iam" {
  source              = "../../modules/iam"
  service_name        = local.name
  dynamodb_table_arns = [module.dynamodb.table_arn]
  tags                = local.tags
}

module "alb" {
  source            = "../../modules/alb"
  name              = local.name
  vpc_id            = var.vpc_id
  public_subnet_ids = var.public_subnet_ids
  target_port       = 8000
  health_check_path = "/health"
  certificate_arn   = var.certificate_arn
  tags              = local.tags
}

module "ecs" {
  source                = "../../modules/ecs"
  cluster_name          = local.name
  service_name          = "idp-platform"
  aws_region            = var.aws_region
  vpc_id                = var.vpc_id
  public_subnet_ids     = var.public_subnet_ids
  alb_security_group_id = module.alb.security_group_id
  target_group_arn      = module.alb.target_group_arn
  execution_role_arn    = module.iam.execution_role_arn
  task_role_arn         = module.iam.task_role_arn
  container_image       = "${data.aws_ecr_repository.app.repository_url}:v3"
  container_port        = 8000
  cpu                   = 256
  memory                = 512
  desired_count         = 1
  assign_public_ip      = true
  environment_variables = {
    ENVIRONMENT = var.environment
    JSON_LOGS   = "true"
  }
  tags = local.tags
}
