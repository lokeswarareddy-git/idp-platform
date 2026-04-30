from fastapi import APIRouter

from app.api.v1.routes import health, provision

router = APIRouter()
router.include_router(health.router, tags=["health"])
router.include_router(provision.router, tags=["provisioning"])
