terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  # Remote state — create S3 bucket + DynamoDB lock table first, then uncomment
  # backend "s3" {
  #   bucket         = "idp-platform-terraform-state"
  #   key            = "idp-platform/terraform.tfstate"
  #   region         = "us-east-2"
  #   dynamodb_table = "idp-platform-terraform-locks"
  #   encrypt        = true
  # }
}
