from typing import Annotated

from fastapi import APIRouter, Depends, status

from app.models.provision import ErrorResponse, ProvisionRequest, ProvisionResponse
from app.services.provision import ProvisionService

router = APIRouter()


def get_provision_service() -> ProvisionService:
    return ProvisionService()


@router.post(
    "/provision",
    response_model=ProvisionResponse,
    status_code=status.HTTP_202_ACCEPTED,
    responses={422: {"model": ErrorResponse, "description": "Validation error"}},
)
async def provision_resource(
    request: ProvisionRequest,
    service: Annotated[ProvisionService, Depends(get_provision_service)],
) -> ProvisionResponse:
    return await service.provision(request)
