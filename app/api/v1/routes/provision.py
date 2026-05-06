from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status

from app.core.exceptions import InsufficientPermissionsError, ResourceAlreadyExistsError
from app.models.provision import ErrorResponse, ProvisionRequest, ProvisionResponse
from app.services.provision import ProvisionService

router = APIRouter()


def get_provision_service() -> ProvisionService:
    return ProvisionService()


@router.post(
    "/provision",
    response_model=ProvisionResponse,
    status_code=status.HTTP_201_CREATED,
    responses={
        403: {"model": ErrorResponse, "description": "Insufficient AWS permissions"},
        409: {"model": ErrorResponse, "description": "Resource already exists"},
        422: {"model": ErrorResponse, "description": "Validation error"},
    },
)
async def provision_resource(
    request: ProvisionRequest,
    service: Annotated[ProvisionService, Depends(get_provision_service)],
) -> ProvisionResponse:
    try:
        return await service.provision(request)
    except InsufficientPermissionsError as e:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=str(e))
    except ResourceAlreadyExistsError as e:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(e))
