# Python API Example

A minimal REST API demonstrating FastAPI patterns.

## Structure

```
python-api/
├── src/
│   ├── __init__.py
│   ├── app.py          # Application factory
│   ├── routes.py       # Route handlers
│   └── models.py       # Pydantic models
└── tests/
    └── test_api.py     # API tests with httpx
```

## Usage

```bash
# Copy to your project
cp -r examples/python-api/src/* src/
cp -r examples/python-api/tests/* tests/

# Install FastAPI (add to your dependencies)
pip install fastapi uvicorn httpx

# Run the server
uvicorn src.app:app --reload

# Run tests
make test
```

## Key Patterns

### Application Factory
```python
# app.py
def create_app() -> FastAPI:
    app = FastAPI(title="My API")
    app.include_router(router)
    return app
```

### Pydantic Models
```python
# models.py - Request/response validation
class Item(BaseModel):
    name: str
    price: float
```

### Testing with httpx
```python
# test_api.py
from httpx import ASGITransport, AsyncClient

async def test_health():
    async with AsyncClient(...) as client:
        response = await client.get("/health")
        assert response.status_code == 200
```

## Extending

Add new endpoints:

1. Define models in `models.py`
2. Add route handlers in `routes.py`
3. Add tests in `test_api.py`

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Health check |
| GET | `/items` | List all items |
| POST | `/items` | Create an item |
| GET | `/items/{id}` | Get item by ID |
