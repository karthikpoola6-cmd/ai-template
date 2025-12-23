"""API route handlers."""

from fastapi import APIRouter, HTTPException
from .models import HealthResponse, Item, ItemCreate, ItemList

router = APIRouter()

# In-memory storage (replace with database in real app)
_items: dict[int, Item] = {}
_next_id: int = 1


@router.get("/health", response_model=HealthResponse)
async def health_check() -> HealthResponse:
    """Health check endpoint."""
    return HealthResponse()


@router.get("/items", response_model=ItemList)
async def list_items() -> ItemList:
    """List all items."""
    return ItemList(items=list(_items.values()), count=len(_items))


@router.post("/items", response_model=Item, status_code=201)
async def create_item(item: ItemCreate) -> Item:
    """Create a new item."""
    global _next_id
    new_item = Item(id=_next_id, **item.model_dump())
    _items[_next_id] = new_item
    _next_id += 1
    return new_item


@router.get("/items/{item_id}", response_model=Item)
async def get_item(item_id: int) -> Item:
    """Get an item by ID."""
    if item_id not in _items:
        raise HTTPException(status_code=404, detail="Item not found")
    return _items[item_id]


def reset_items() -> None:
    """Reset items storage (for testing)."""
    global _items, _next_id
    _items = {}
    _next_id = 1
