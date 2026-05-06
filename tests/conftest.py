import os

import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from moto import mock_aws

from app.main import app


@pytest_asyncio.fixture
async def client() -> AsyncClient:
    os.environ.update(
        {
            "AWS_ACCESS_KEY_ID": "testing",
            "AWS_SECRET_ACCESS_KEY": "testing",
            "AWS_SECURITY_TOKEN": "testing",
            "AWS_SESSION_TOKEN": "testing",
            "AWS_DEFAULT_REGION": "us-east-1",
        }
    )
    with mock_aws():
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
            yield ac
