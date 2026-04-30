import uuid
from datetime import UTC, datetime

import structlog

from app.models.provision import ProvisionRequest, ProvisionResponse, ProvisionStatus

log = structlog.get_logger(__name__)


class ProvisionService:
    async def provision(self, request: ProvisionRequest) -> ProvisionResponse:
        request_id = str(uuid.uuid4())

        log.info(
            "provision.requested",
            request_id=request_id,
            resource_type=request.config.resource_type,
            name=request.name,
            environment=request.environment,
            owner_team=request.owner_team,
        )

        # Production: enqueue to SQS, Temporal, or similar async worker.
        # The worker reads the request_id to track and report provisioning state.

        response = ProvisionResponse(
            request_id=request_id,
            name=request.name,
            resource_type=request.config.resource_type,
            environment=request.environment,
            owner_team=request.owner_team,
            status=ProvisionStatus.ACCEPTED,
            requested_at=datetime.now(UTC),
            message=(
                f"Provisioning of {request.config.resource_type} "
                f"resource '{request.name}' accepted."
            ),
        )

        log.info("provision.accepted", request_id=request_id)
        return response
