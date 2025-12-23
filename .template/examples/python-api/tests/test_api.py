"""Tests for the API endpoints."""

import pytest
from httpx import ASGITransport, AsyncClient
from src.app import app
from src.routes import reset_items


@pytest.fixture(autouse=True)
def clean_items():
    """Reset items before each test."""
    reset_items()
    yield
    reset_items()


@pytest.fixture
async def client():
    """Create async test client."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client


class TestHealth:
    """Tests for health endpoint."""

    @pytest.mark.asyncio
    async def test_health_returns_ok(self, client):
        """Health check should return ok status."""
        response = await client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ok"
        assert "version" in data


class TestItems:
    """Tests for items endpoints."""

    @pytest.mark.asyncio
    async def test_list_items_empty(self, client):
        """Should return empty list initially."""
        response = await client.get("/items")
        assert response.status_code == 200
        data = response.json()
        assert data["items"] == []
        assert data["count"] == 0

    @pytest.mark.asyncio
    async def test_create_item(self, client):
        """Should create an item."""
        response = await client.post(
            "/items",
            json={"name": "Test Item", "price": 9.99},
        )
        assert response.status_code == 201
        data = response.json()
        assert data["name"] == "Test Item"
        assert data["price"] == 9.99
        assert "id" in data

    @pytest.mark.asyncio
    async def test_get_item(self, client):
        """Should get item by ID."""
        # Create item first
        create_response = await client.post(
            "/items",
            json={"name": "Test Item", "price": 9.99},
        )
        item_id = create_response.json()["id"]

        # Get the item
        response = await client.get(f"/items/{item_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == item_id
        assert data["name"] == "Test Item"

    @pytest.mark.asyncio
    async def test_get_item_not_found(self, client):
        """Should return 404 for missing item."""
        response = await client.get("/items/999")
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_create_item_validation(self, client):
        """Should validate item data."""
        # Missing required field
        response = await client.post("/items", json={"name": "Test"})
        assert response.status_code == 422

        # Invalid price
        response = await client.post(
            "/items",
            json={"name": "Test", "price": -1},
        )
        assert response.status_code == 422
