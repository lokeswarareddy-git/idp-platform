# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.
# CLAUDE.md

## 🧠 Project Context

This is an **IDP Platform backend service** built using:

* FastAPI (Python 3.12)
* Dockerized microservice
* Deployed on AWS ECS Fargate
* Fronted by AWS Application Load Balancer (ALB)
* Container images stored in AWS ECR

---

## 🏗️ Architecture Overview

* ALB routes traffic → ECS Service
* ECS runs Fargate tasks (FastAPI container)
* Container exposes port `8000`
* `/health` endpoint used for ALB health checks
* Images pulled from ECR (`idp-platform` repository)

---

## 🚀 Deployment Flow

1. Build Docker image locally
2. Tag image (example: `v10`, `v11`)
3. Push to ECR
4. Update ECS task definition with new image
5. ECS service deploys new task revision
6. ALB performs health checks on `/health`
7. Traffic routed only when target is healthy

---

## 📦 AWS Resources

### ECS

* Cluster: `idp-platform-dev`
* Service: `idp-platform`
* Launch type: Fargate
* Port: `8000`

### ECR

* Repository: `idp-platform`
* Image format: `332896939145.dkr.ecr.us-east-2.amazonaws.com/idp-platform:<tag>`
* Tags are **immutable**

### ALB

* Listener: HTTP
* Target Group: `/health` health check path
* Returns 503 if targets are unhealthy

### CloudWatch

* Logs: `/ecs/idp-platform`
* Metrics:

  * CPU high
  * Memory high
  * ALB 5xx errors
  * Unhealthy hosts

---

## ⚙️ Application Details

### Entry Point

```
app/main.py
```

### FastAPI App

* Created via `create_app()`
* Includes:

  * `/health` endpoint
  * `/api/v1/*` routes

### Server

* Uvicorn running on `0.0.0.0:8000`

---

## 📌 Important Constraints

* ECR tags are **immutable**
* ECS task will fail if image tag does not exist
* ALB requires multiple successful `/health` checks before routing traffic
* If container crashes → ECS replaces task automatically

---

## 🧪 Debugging Checklist

### If ECS task is not running:

* Check `aws ecs describe-tasks`
* Look for:

  * `CannotPullContainerError`
  * `ModuleNotFoundError`

### If ALB returns 503:

* Check target health:

  * `/health` must return 200
* Ensure ECS task is running
* Ensure security group allows port 8000

### If container crashes:

* Check CloudWatch logs:

  * `/ecs/idp-platform`

---

## 🧠 Known Issues (Resolved)

* Fixed ECR image pull failures (missing tags)
* Fixed ALB health check instability
* Fixed ECS task restart loops
* Fixed Python import/module resolution issues
* Fixed Terraform variable misconfiguration (`container_image`)

---

## 🔮 Future Improvements

* CI/CD pipeline (GitHub Actions → ECR → ECS deploy)
* Blue/Green deployments via CodeDeploy
* Auto scaling policies (CPU/Memory based)
* Separate dev/stage/prod environments
* Add OpenTelemetry tracing

---

## 👤 Owner

Lokesh


## Commands

```bash
# Install (requires Python 3.12+)
pip install -e ".[dev]"

# Run locally with auto-reload
uvicorn app.main:app --reload --port 8000

# Run all tests
pytest

# Run a single test class or case
pytest tests/test_provision.py::TestProvision::test_s3_provision_accepted -v

# Lint / format
ruff check .
ruff format .

# Docker
docker build -t idp-platform .
docker-compose up
```

## Architecture

Three layers, strictly separated:

| Layer | Location | Responsibility |
|---|---|---|
| Routes | `app/api/v1/routes/` | HTTP in/out only — delegates immediately to service |
| Services | `app/services/` | Business logic, logging, async dispatch |
| Models | `app/models/` | Pydantic v2 request/response contracts |

Cross-cutting concerns live in `app/core/`: `config.py` (pydantic-settings, env-driven) and `logging.py` (structlog + stdlib bridge so uvicorn logs are also JSON-formatted).

### Request lifecycle

1. `app/main.py` middleware injects `request_id` (from `X-Request-ID` header or a new UUID) into `structlog.contextvars` — every log line within that request automatically carries it.
2. The same `request_id` is echoed in the `X-Request-ID` response header for client-side correlation.
3. Routes call services; services do the work and log structured events (`provision.requested`, `provision.accepted`).
4. `POST /provision` returns `202 Accepted` — the intent is async: a real implementation enqueues to SQS / Temporal / Celery in `ProvisionService.provision()`.

### Resource type validation

`ProvisionRequest.config` is a Pydantic v2 **discriminated union** keyed on `resource_type`:

```python
config: Annotated[Union[S3Config, DynamoDBConfig], Field(discriminator="resource_type")]
```

To add a new resource type (e.g. `sqs`):
1. Add `SQSConfig(BaseModel)` with `resource_type: Literal["sqs"]` in `app/models/provision.py`
2. Add `SQSConfig` to the `Union` in `ProvisionRequest.config`
3. Add resource-specific logic in `ProvisionService.provision()` if needed
4. Add test cases in `tests/test_provision.py`

### Logging

`JSON_LOGS=false` switches to human-readable console output for local dev. In any mode, bind extra context fields at the call site:

```python
log.info("my.event", key="value", other=123)
```

### Docs UI

Swagger UI is available at `/docs` in `dev` and `staging` only — disabled automatically when `ENVIRONMENT=prod`.
