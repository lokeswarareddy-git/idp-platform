aws_region  = "us-east-2"
environment = "prod"

# Fill in your VPC and subnet IDs
vpc_id             = ""
public_subnet_ids  = []
private_subnet_ids = []

# Required in prod: ACM certificate ARN
certificate_arn = ""

# Pin to a specific image tag — never use "latest" in prod
image_tag = ""
