FROM python:3.12-slim-bookworm AS builder

ENV PYTHONDONTWRITEBYTECODE=1

WORKDIR /build

COPY pyproject.toml .

RUN python -m venv /venv && \
    /venv/bin/pip install --upgrade pip && \
    /venv/bin/pip install fastapi uvicorn pydantic pydantic-settings structlog

FROM python:3.12-slim-bookworm AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/venv/bin:$PATH"

RUN addgroup --system app && adduser --system --group app

COPY --from=builder /venv /venv

WORKDIR /app
COPY app/ ./app/

USER app

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/docs')"

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]