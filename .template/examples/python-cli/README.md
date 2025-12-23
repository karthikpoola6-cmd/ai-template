# Python CLI Example

A minimal command-line tool demonstrating testable CLI structure.

## Structure

```
python-cli/
├── src/
│   ├── __init__.py
│   ├── cli.py          # Entry point and argument parsing
│   └── commands.py     # Command implementations
└── tests/
    └── test_cli.py     # Tests for commands
```

## Usage

```bash
# Copy to your project
cp -r examples/python-cli/src/* src/
cp -r examples/python-cli/tests/* tests/

# Run the CLI
python -m src.cli greet --name "World"
python -m src.cli add 2 3

# Run tests
make test
```

## Key Patterns

### Separation of Concerns
- `cli.py` handles argument parsing
- `commands.py` contains business logic
- Makes testing easier (test logic without parsing)

### Testable Commands
```python
# commands.py - Pure functions, easy to test
def greet(name: str) -> str:
    return f"Hello, {name}!"

# test_cli.py - Direct testing
def test_greet():
    assert greet("World") == "Hello, World!"
```

## Extending

Add new commands:

1. Add function to `commands.py`
2. Add subparser to `cli.py`
3. Add tests to `test_cli.py`
