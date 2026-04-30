# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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
