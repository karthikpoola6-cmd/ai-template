"""Pydantic models for request/response validation."""

from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    """Health check response."""

    status: str = "ok"
    version: str = "1.0.0"


class ItemCreate(BaseModel):
    """Request model for creating an item."""

    name: str = Field(..., min_length=1, max_length=100)
    price: float = Field(..., gt=0)
    description: str | None = None


class Item(BaseModel):
    """Response model for an item."""

    id: int
    name: str
    price: float
    description: str | None = None


class ItemList(BaseModel):
    """Response model for list of items."""

    items: list[Item]
    count: int
