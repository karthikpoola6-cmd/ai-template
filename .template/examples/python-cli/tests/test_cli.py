"""Tests for CLI commands."""

from src.commands import add, greet, version


class TestGreet:
    """Tests for the greet command."""

    def test_greet_with_name(self):
        """Should greet the provided name."""
        assert greet("Alice") == "Hello, Alice!"

    def test_greet_with_world(self):
        """Should greet World."""
        assert greet("World") == "Hello, World!"

    def test_greet_with_empty_string(self):
        """Should handle empty string."""
        assert greet("") == "Hello, !"


class TestAdd:
    """Tests for the add command."""

    def test_add_positive_numbers(self):
        """Should add positive numbers."""
        assert add(2, 3) == 5

    def test_add_negative_numbers(self):
        """Should add negative numbers."""
        assert add(-1, -1) == -2

    def test_add_mixed_numbers(self):
        """Should add mixed positive and negative."""
        assert add(-1, 5) == 4

    def test_add_zero(self):
        """Should handle zero."""
        assert add(0, 5) == 5
        assert add(5, 0) == 5


class TestVersion:
    """Tests for the version command."""

    def test_version_returns_string(self):
        """Should return a version string."""
        v = version()
        assert isinstance(v, str)
        assert len(v) > 0

    def test_version_format(self):
        """Should return semver-like format."""
        v = version()
        parts = v.split(".")
        assert len(parts) == 3
