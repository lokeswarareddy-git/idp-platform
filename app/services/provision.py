import asyncio
import uuid
from datetime import UTC, datetime

import boto3
import structlog
from botocore.exceptions import ClientError
from fastapi import HTTPException, status as http_status

from app.core.config import settings
from app.core.exceptions import InsufficientPermissionsError, ResourceAlreadyExistsError
from app.models.provision import (
    DynamoDBConfig,
    ProvisionRequest,
    ProvisionResponse,
    ProvisionStatus,
    S3Config,
)

log = structlog.get_logger(__name__)

_SYSTEM_TAGS = {"managed_by": "idp-platform"}


def _account_id() -> str:
    return boto3.client("sts", region_name=settings.aws_region).get_caller_identity()["Account"]


class ProvisionService:
    async def provision(self, request: ProvisionRequest) -> ProvisionResponse:
        request_id = str(uuid.uuid4())
        account_id = await asyncio.to_thread(_account_id)
        # Prefix account ID so S3 bucket names are globally unique
        resource_name = f"{account_id}-{request.environment}-{request.name}"
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
        except ClientError as e:
            if e.response["Error"]["Code"] in ("AccessDenied", "AccessDeniedException"):
                action = e.response["Error"].get("Message", "unknown AWS action")
                log.warning("provision.access_denied", request_id=request_id, detail=action)
                raise InsufficientPermissionsError(action) from e
            raise

        log.info("provision.completed", request_id=request_id, resource_arn=resource_arn)

        return ProvisionResponse(
            request_id=request_id,
            name=request.name,
            resource_type=request.config.resource_type,
            environment=request.environment,
            owner_team=request.owner_team,
            status=ProvisionStatus.COMPLETED,
            requested_at=datetime.now(UTC),
            resource_arn=resource_arn,
            message=f"{request.config.resource_type.upper()} '{resource_name}' provisioned.",
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
        if code == "BucketAlreadyOwnedByYou":
            # You already own this bucket — idempotent, return its ARN
            return f"arn:aws:s3:::{bucket_name}"
        if code == "BucketAlreadyExists":
            # Name taken by another account — should not happen with account-prefixed names
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
