---

## 🤖 AI-Native Development Workflow

This project was built using Claude Code as an AI engineering assistant.

Claude was used to:
- Design Terraform infrastructure modules
- Build CI/CD pipeline using GitHub Actions
- Debug ECS deployment and ALB health check issues
- Resolve IAM OIDC authentication configuration
- Assist in AWS troubleshooting using iterative feedback loops

### Human Validation Approach

All AI-generated outputs were validated using:
- AWS CLI commands
- ECS service and task inspection
- CloudWatch logs analysis
- Real deployment testing on AWS

### Key Principle

AI was used as a **development accelerator**, not as an autonomous system.
All infrastructure and deployment decisions were verified through live AWS execution.

---

## 🚀 Outcome

The final system demonstrates:
- Fully automated CI/CD pipeline
- Infrastructure as Code using Terraform
- Secure AWS authentication (OIDC)
- Containerized deployment on ECS Fargate
- Observability using CloudWatch and SNS