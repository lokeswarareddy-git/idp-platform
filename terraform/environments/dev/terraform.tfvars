aws_region  = "us-east-2"
environment = "dev"

vpc_id             = "vpc-03ea6ab7d78c7697b"
public_subnet_ids  = ["subnet-0d06bb43de55a851f", "subnet-0a55f1a5dbd3ca5b9", "subnet-066decd710f8c981c"]
private_subnet_ids = ["subnet-0d06bb43de55a851f", "subnet-0a55f1a5dbd3ca5b9", "subnet-066decd710f8c981c"]

# Leave empty to use plain HTTP; add ACM cert ARN to enable HTTPS
certificate_arn = ""
