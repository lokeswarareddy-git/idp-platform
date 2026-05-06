import asyncio
import uuid
from datetime import UTC, datetime

import boto3
import structlog
from botocore.exceptions import ClientError
from fastapi import HTTPException, status as http_status

from app.core.config import settings
from app.core.exceptions import ResourceAlreadyExistsError
from app.models.provision import (
    DynamoDBConfig,
    ProvisionRequest,
    ProvisionResponse,
    ProvisionStatus,
    S3Config,
)

log = structlog.get_logger(__name__)

_SYSTEM_TAGS = {"managed_by": "idp-platform"}


class ProvisionService:
    async def provision(self, request: ProvisionRequest) -> ProvisionResponse:
        request_id = str(uuid.uuid4())
        resource_name = f"{request.environment}-{request.name}"
        tags = {
            **request.tags,
            **_SYSTEM_TAGS,
            "environment": request.environment,
            "owner_team": request.owner_team,
        }

        log.info(
            "provision.started",
            request_id=request_id,
            resource_type=request.config.resource_type,
            name=resource_name,
        )

        try:
            if isinstance(request.config, S3Config):
                resource_arn = await asyncio.to_thread(
                    _provision_s3, resource_name, request.config, tags
                )
            else:
                resource_arn = await asyncio.to_thread(
                    _provision_dynamodb, resource_name, request.config, tags
                )

            status = ProvisionStatus.COMPLETED
            message = f"{request.config.resource_type.upper()} '{resource_name}' provisioned."

        except ResourceAlreadyExistsError:
            if isinstance(request.config, S3Config):
                # ✅ S3 → idempotent
                resource_arn = f"existing:{resource_name}"
                status = ProvisionStatus.COMPLETED
                message = f"S3 '{resource_name}' already exists (idempotent)."
            else:
                # ❌ DynamoDB → conflict
                raise HTTPException(
                    status_code=http_status.HTTP_409_CONFLICT,
                    detail=f"DynamoDB '{resource_name}' already exists",
                )

        log.info("provision.completed", request_id=request_id, resource_arn=resource_arn)

        return ProvisionResponse(
            request_id=request_id,
            name=request.name,
            resource_type=request.config.resource_type,
            environment=request.environment,
            owner_team=request.owner_team,
            status=status,
            requested_at=datetime.now(UTC),
            resource_arn=resource_arn,
            message=message,
        )

def _provision_s3(bucket_name: str, config: S3Config, tags: dict[str, str]) -> str:
    client = boto3.client("s3", region_name=settings.aws_region)
    tag_set = [{"Key": k, "Value": v} for k, v in tags.items()]

    try:
        kwargs: dict = {"Bucket": bucket_name}
        if settings.aws_region != "us-east-1":
            kwargs["CreateBucketConfiguration"] = {"LocationConstraint": settings.aws_region}
        client.create_bucket(**kwargs)
    except ClientError as e:
        code = e.response["Error"]["Code"]
        if code in ("BucketAlreadyExists", "BucketAlreadyOwnedByYou"):
            raise ResourceAlreadyExistsError("s3", bucket_name) from e
        raise

    if config.public_access_blocked:
        client.put_public_access_block(
            Bucket=bucket_name,
            PublicAccessBlockConfiguration={
                "BlockPublicAcls": True,
                "IgnorePublicAcls": True,
                "BlockPublicPolicy": True,
                "RestrictPublicBuckets": True,
            },
        )

    if config.versioning_enabled:
        client.put_bucket_versioning(
            Bucket=bucket_name,
            VersioningConfiguration={"Status": "Enabled"},
        )

    if tag_set:
        client.put_bucket_tagging(Bucket=bucket_name, Tagging={"TagSet": tag_set})

    return f"arn:aws:s3:::{bucket_name}"


def _provision_dynamodb(table_name: str, config: DynamoDBConfig, tags: dict[str, str]) -> str:
    client = boto3.client("dynamodb", region_name=settings.aws_region)

    key_schema = [{"AttributeName": config.hash_key, "KeyType": "HASH"}]
    attr_defs = [{"AttributeName": config.hash_key, "AttributeType": "S"}]

    if config.range_key:
        key_schema.append({"AttributeName": config.range_key, "KeyType": "RANGE"})
        attr_defs.append({"AttributeName": config.range_key, "AttributeType": "S"})

    kwargs: dict = {
        "TableName": table_name,
        "KeySchema": key_schema,
        "AttributeDefinitions": attr_defs,
        "BillingMode": config.billing_mode,
        "Tags": [{"Key": k, "Value": v} for k, v in tags.items()],
    }

    if config.billing_mode == "PROVISIONED":
        kwargs["ProvisionedThroughput"] = {
            "ReadCapacityUnits": 5,
            "WriteCapacityUnits": 5,
        }

    try:
        response = client.create_table(**kwargs)
    except ClientError as e:
        if e.response["Error"]["Code"] == "ResourceInUseException":
            raise ResourceAlreadyExistsError("dynamodb", table_name) from e
        raise

    return response["TableDescription"]["TableArn"]
