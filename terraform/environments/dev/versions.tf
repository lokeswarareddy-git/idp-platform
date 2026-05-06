terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  # Uncomment after creating the S3 bucket and DynamoDB lock table
   backend "s3" {
     bucket         = "idp-platform-terraform-state"
     key            = "dev/terraform.tfstate"
     region         = "us-east-2"
     dynamodb_table = "idp-platform-terraform-locks"
     encrypt        = true
   }
}
