provider "aws" {
  region = "us-east-2"
}

module "ecr" {
  source = "./modules/ecr"
  name   = "idp-platform"
  tags = {
    Project     = "idp-platform"
    ManagedBy   = "terraform"
  }
}
