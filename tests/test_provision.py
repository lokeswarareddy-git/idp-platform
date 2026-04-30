import pytest
from httpx import AsyncClient


class TestHealth:
    async def test_returns_ok(self, client: AsyncClient) -> None:
        response = await client.get("/api/v1/health")
        assert response.status_code == 200
        assert response.json()["status"] == "ok"


class TestProvision:
    S3_PAYLOAD = {
        "name": "my-data-bucket",
        "environment": "dev",
        "owner_team": "platform-team",
        "config": {
            "resource_type": "s3",
            "versioning_enabled": True,
            "public_access_blocked": True,
        },
    }

    DYNAMO_PAYLOAD = {
        "name": "user-events-table",
        "environment": "staging",
        "owner_team": "backend-team",
        "config": {
            "resource_type": "dynamodb",
            "billing_mode": "PAY_PER_REQUEST",
            "hash_key": "userId",
            "range_key": "timestamp",
        },
    }

    async def test_s3_provision_accepted(self, client: AsyncClient) -> None:
        response = await client.post("/api/v1/provision", json=self.S3_PAYLOAD)
        assert response.status_code == 202
        data = response.json()
        assert data["resource_type"] == "s3"
        assert data["status"] == "accepted"
        assert data["name"] == "my-data-bucket"
        assert data["environment"] == "dev"
        assert data["owner_team"] == "platform-team"
        assert "request_id" in data
        assert "requested_at" in data

    async def test_dynamodb_provision_accepted(self, client: AsyncClient) -> None:
        response = await client.post("/api/v1/provision", json=self.DYNAMO_PAYLOAD)
        assert response.status_code == 202
        data = response.json()
        assert data["resource_type"] == "dynamodb"
        assert data["status"] == "accepted"

    async def test_response_includes_request_id_header(self, client: AsyncClient) -> None:
        response = await client.post("/api/v1/provision", json=self.S3_PAYLOAD)
        assert response.status_code == 202
        assert "X-Request-ID" in response.headers

    async def test_custom_request_id_propagated(self, client: AsyncClient) -> None:
        custom_id = "trace-abc-123"
        response = await client.post(
            "/api/v1/provision",
            json=self.S3_PAYLOAD,
            headers={"X-Request-ID": custom_id},
        )
        assert response.headers["X-Request-ID"] == custom_id

    async def test_invalid_resource_type_rejected(self, client: AsyncClient) -> None:
        payload = {**self.S3_PAYLOAD, "config": {"resource_type": "ec2"}}
        response = await client.post("/api/v1/provision", json=payload)
        assert response.status_code == 422

    async def test_invalid_name_pattern_rejected(self, client: AsyncClient) -> None:
        payload = {**self.S3_PAYLOAD, "name": "My_Invalid_Name!!"}
        response = await client.post("/api/v1/provision", json=payload)
        assert response.status_code == 422

    async def test_name_too_short_rejected(self, client: AsyncClient) -> None:
        payload = {**self.S3_PAYLOAD, "name": "ab"}
        response = await client.post("/api/v1/provision", json=payload)
        assert response.status_code == 422

    async def test_invalid_environment_rejected(self, client: AsyncClient) -> None:
        payload = {**self.S3_PAYLOAD, "environment": "production"}
        response = await client.post("/api/v1/provision", json=payload)
        assert response.status_code == 422

    async def test_too_many_tags_rejected(self, client: AsyncClient) -> None:
        payload = {
            **self.S3_PAYLOAD,
            "tags": {f"key{i}": f"val{i}" for i in range(11)},
        }
        response = await client.post("/api/v1/provision", json=payload)
        assert response.status_code == 422

    async def test_missing_required_fields_rejected(self, client: AsyncClient) -> None:
        response = await client.post("/api/v1/provision", json={"name": "my-bucket"})
        assert response.status_code == 422

    async def test_dynamodb_missing_hash_key_rejected(self, client: AsyncClient) -> None:
        payload = {
            **self.S3_PAYLOAD,
            "config": {"resource_type": "dynamodb"},
        }
        response = await client.post("/api/v1/provision", json=payload)
        assert response.status_code == 422
