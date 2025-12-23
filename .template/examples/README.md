# Examples

Minimal, runnable examples showing common project patterns. These are **reference implementations** - copy what you need to your `src/` and `tests/` directories.

## Available Examples

| Example | Description | Copy to use |
|---------|-------------|-------------|
| [python-cli](./python-cli/) | Command-line tool with argparse | `cp -r examples/python-cli/src/* src/` |
| [python-api](./python-api/) | REST API with FastAPI | `cp -r examples/python-api/src/* src/` |
| [go-service](./go-service/) | HTTP service in Go | `cp examples/go-service/*.go .` |

## How to Use

1. **Browse** the example that matches your use case
2. **Copy** the files you need to your project
3. **Adapt** to your specific requirements

```bash
# Example: Start with the Python CLI pattern
cp -r examples/python-cli/src/* src/
cp -r examples/python-cli/tests/* tests/

# Run tests to verify
make test
```

## What Each Example Demonstrates

### Python CLI
- Argument parsing with `argparse`
- Testable command structure
- Entry point pattern

### Python API
- FastAPI application factory
- Health check endpoint
- Request/response testing with `httpx`

### Go Service
- Standard library HTTP server
- Handler testing
- Graceful structure for small services

## These Are Starting Points

Each example is intentionally minimal. They demonstrate:
- How to structure code for the template's tooling
- Patterns that work well with `make test` and `make quality`
- Testable code organization

They don't include:
- Database connections
- Authentication
- Complex business logic

Add those based on your project's needs.
