# IDP Platform

An Internal Developer Platform (IDP) that lets teams self-serve cloud infrastructure (S3 buckets, DynamoDB tables) through a REST API — no AWS console access or Terraform knowledge required.

---

## Architecture

```
                        ┌─────────────────────────────────────────────────┐
                        │                   GitHub                        │
                        │  ┌─────────────┐       ┌──────────────────────┐ │
                        │  │  GitHub     │       │  GitHub Actions      │ │
                        │  │  Repository │──PR──▶│  CI/CD Pipeline      │ │
                        │  └─────────────┘       │  - pytest            │ │
                        │                        │  - docker build/push │ │
                        │                        │  - ecs deploy        │ │
                        │                        └─────────┬────────────┘ │
                        └──────────────────────────────────┼──────────────┘
                                                           │ OIDC (no keys)
                                          ┌────────────────▼─────────────┐
                                          │           AWS                │
                                          │                              │
          Internet                        │  ┌──────────┐  ┌─────────┐  │
    ─────────────────▶  ALB  ──────────────▶ │   ECS    │  │  ECR    │  │
         HTTP :80                        │  │  Fargate │◀─│  Image  │  │
                                         │  │  (FastAPI│  └─────────┘  │
                                         │  │  + boto3)│               │
                                         │  └────┬─────┘               │
                                         │       │                      │
                                         │  ┌────▼──────────────────┐  │
                                         │  │  Provisions on demand │  │
                                         │  │  ┌────────┐ ┌───────┐ │  │
                                         │  │  │  S3    │ │Dynamo │ │  │
                                         │  │  │Buckets │ │  DB   │ │  │
                                         │  │  └────────┘ └───────┘ │  │
                                         │  └───────────────────────┘  │
                                         │                              │
                                         │  ┌───────────────────────┐  │
                                         │  │  Terraform State      │  │
                                         │  │  S3 + DynamoDB lock   │  │
                                         │  └───────────────────────┘  │
                                         └──────────────────────────────┘
```

**Request flow:** Client → ALB → ECS Fargate (FastAPI) → boto3 → S3 / DynamoDB

---

## Tech Stack

| Layer | Technology |
|---|---|
| API | FastAPI (Python 3.12), Pydantic v2, structlog |
| Runtime | AWS ECS Fargate |
| Load Balancer | AWS Application Load Balancer |
| Container Registry | AWS ECR |
| Infrastructure as Code | Terraform (modular) |
| CI/CD | GitHub Actions + OIDC (no static credentials) |
| State Backend | S3 + DynamoDB locking |
| Testing | pytest, moto (AWS mocks) |

---

## API Reference

Base URL: `http://idp-platform-dev-1818549407.us-east-2.elb.amazonaws.com`

Interactive docs: `/docs`

### Health check

```
GET /api/v1/health
```

```json
{"status": "ok"}
```

### Provision S3 bucket

```
POST /api/v1/provision
```

```json
{
  "name": "my-data-bucket",
  "environment": "dev",
  "owner_team": "platform-team",
  "config": {
    "resource_type": "s3",
    "versioning_enabled": true,
    "public_access_blocked": true
  }
}
```

Response `201 Created`:
```json
{
  "request_id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "my-data-bucket",
  "resource_type": "s3",
  "environment": "dev",
  "owner_team": "platform-team",
  "status": "completed",
  "requested_at": "2026-05-05T12:00:00Z",
  "resource_arn": "arn:aws:s3:::123456789012-dev-my-data-bucket",
  "message": "S3 '123456789012-dev-my-data-bucket' provisioned."
}
```

### Provision DynamoDB table

```
POST /api/v1/provision
```

```json
{
  "name": "user-events-table",
  "environment": "staging",
  "owner_team": "backend-team",
  "config": {
    "resource_type": "dynamodb",
    "billing_mode": "PAY_PER_REQUEST",
    "hash_key": "userId",
    "range_key": "timestamp"
  }
}
```

Response `201 Created`:
```json
{
  "request_id": "...",
  "resource_type": "dynamodb",
  "status": "completed",
  "resource_arn": "arn:aws:dynamodb:us-east-2:123456789012:table/...-user-events-table"
}
```

### Error responses

| Status | Meaning |
|---|---|
| `201` | Resource provisioned successfully |
| `403` | ECS task role lacks permission for the requested AWS action |
| `409` | Resource already exists (DynamoDB only — S3 is idempotent) |
| `422` | Invalid request payload (see validation rules below) |

**Validation rules:**
- `name`: 3–63 chars, lowercase letters/digits/hyphens only
- `environment`: one of `dev`, `staging`, `prod`
- `tags`: max 10 key-value pairs
- DynamoDB requires `hash_key`; `range_key` is optional

---

## Local Development

### Prerequisites

- Python 3.12
- Docker (optional, for container testing)
- AWS credentials with S3 + DynamoDB permissions (or use moto for local testing)

### Install and run

```bash
git clone https://github.com/<your-org>/idp-platform
cd idp-platform

python -m venv .venv && source .venv/bin/activate
pip install -e ".[dev]"

# Set required env vars
export AWS_REGION=us-east-2
export AWS_ACCESS_KEY_ID=test      # or real credentials
export AWS_SECRET_ACCESS_KEY=test

uvicorn app.main:app --reload
# → http://localhost:8000/docs
```

### Run tests

```bash
pytest --tb=short -q
```

Tests use [moto](https://github.com/getmoto/moto) to mock AWS — no real AWS account needed.

---

## Infrastructure

Terraform modules under `terraform/`:

```
terraform/
├── modules/
│   ├── ecr/          # Container registry
│   ├── ecs/          # Fargate cluster, task definition, service
│   ├── iam/          # Execution + task roles, least-privilege policies
│   ├── alb/          # Load balancer, target group, listener
│   ├── networking/   # VPC, subnets, security groups
│   └── cloudwatch/   # Log groups
└── environments/
    └── dev/          # Dev environment (single active environment)
```

### Deploy infrastructure

```bash
cd terraform/environments/dev
terraform init
terraform plan
terraform apply
```

State is stored in S3 with DynamoDB locking — safe for team use.

---

## CI/CD

The GitHub Actions workflow (`.github/workflows/deploy.yml`) runs on every push to `main` and on pull requests:

1. **Test** — runs `pytest` (all tests use moto, no AWS needed)
2. **Build & Deploy** (main branch only):
   - Authenticates to AWS via OIDC (no stored credentials)
   - Builds and pushes Docker image to ECR
   - Updates ECS task definition with new image
   - Deploys to ECS Fargate

The Terraform workflow (`.github/workflows/terraform.yml`) runs `plan` on PRs and `apply` on merge to main.

### Required GitHub secrets

| Secret | Value |
|---|---|
| `AWS_DEPLOY_ROLE_ARN` | ARN of the IAM role GitHub assumes via OIDC |

---

## AI-Native Development

This project was built using [Claude Code](https://claude.ai/claude-code) as a development accelerator across infrastructure, CI/CD, and application layers. All AI-generated outputs were validated through real AWS deployments, CLI verification, and CloudWatch logs.

See [CLAUDE.md](CLAUDE.md) for details on where AI assistance was used and its limitations.
