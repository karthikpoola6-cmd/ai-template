"""Command implementations.

Business logic lives here, separate from CLI parsing.
This makes commands easy to test and reuse.
"""


def greet(name: str) -> str:
    """Generate a greeting message.

    Args:
        name: The name to greet.

    Returns:
        A greeting string.
    """
    return f"Hello, {name}!"


def add(a: int, b: int) -> int:
    """Add two numbers.

    Args:
        a: First number.
        b: Second number.

    Returns:
        Sum of a and b.
    """
    return a + b


def version() -> str:
    """Return the version string."""
    return "1.0.0"
