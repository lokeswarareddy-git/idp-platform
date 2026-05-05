# 🧠 Architecture & Design Decisions

This document outlines key engineering decisions made during the design and implementation of the IDP platform.

---

## 1. Compute Choice: ECS Fargate

### Decision
Used AWS ECS Fargate for running containerized workloads.

### Reasoning
- Serverless container execution
- No EC2 management overhead
- Native AWS integration with ALB and IAM
- Easy scaling and deployment

### Alternatives Considered
- ECS on EC2 (rejected due to operational overhead)
- AWS Lambda (rejected due to long-running service constraints)

---

## 2. Infrastructure as Code: Terraform

### Decision
Terraform used for all infrastructure provisioning.

### Reasoning
- Modular architecture support
- Reusability across environments
- Industry standard for platform engineering
- Supports state-based infrastructure management

---

## 3. CI/CD System: GitHub Actions

### Decision
GitHub Actions used for CI/CD pipeline.

### Reasoning
- Native GitHub integration
- Simple OIDC authentication with AWS
- No external CI/CD system required
- Easy debugging and observability

---

## 4. Authentication: GitHub OIDC

### Decision
Used OIDC-based IAM role assumption instead of static AWS credentials.

### Reasoning
- Eliminates long-lived credentials
- Improves security posture
- Aligns with AWS best practices
- Enables temporary, scoped access tokens

---

## 5. Deployment Strategy

### Decision
Immutable container deployments via ECS task definition updates.

### Reasoning
- Clean rollback capability
- Versioned deployments
- No in-place modifications
- Production-grade reliability

---

## 6. Observability Strategy

### Decision
Used CloudWatch logs + ECS metrics + SNS alerts.

### Reasoning
- Native AWS observability stack
- Minimal operational overhead
- Sufficient for MVP production monitoring

---

## 7. AI-Assisted Development

### Decision
Claude Code used as an engineering assistant.

### Reasoning
- Faster Terraform and CI/CD development
- Assisted debugging of AWS issues
- Accelerated iterative infrastructure development

---

## Key Insight

AI improved speed of development, but AWS CLI + real deployment validation was used as the source of truth for correctness.