#!/usr/bin/env python3
"""
Template Engine for Codespaces AI Template
==========================================

A lightweight, extensible template engine that processes template files
with variable substitution and conditional blocks.

SYNTAX
------
Variables:
    {{VAR_NAME}}              → Substituted with value from VARIABLES registry

Conditionals:
    {{#IF_CONDITION}}         → Include block if condition is true
    ...content...
    {{/IF_CONDITION}}

    {{#IF_CONDITION}}         → Include if-block or else-block
    ...if content...
    {{#ELSE}}
    ...else content...
    {{/IF_CONDITION}}

EXTENDING
---------
To add a new variable:
    1. Add to VARIABLES dict in the "Variable Definitions" section
    2. For derived variables, add computation in get_variables()

To add a new condition:
    1. Add to CONDITIONS dict in the "Condition Definitions" section
    2. The value should be a callable that returns bool

USAGE
-----
    python3 template_engine.py <input_template> <output_file>

Environment variables are used as the source for template values.
"""

from __future__ import annotations

import os
import re
import sys
from collections.abc import Callable
from dataclasses import dataclass
from pathlib import Path


# =============================================================================
# CONFIGURATION - Edit these sections to extend the template engine
# =============================================================================

# -----------------------------------------------------------------------------
# Variable Definitions
# -----------------------------------------------------------------------------
# Maps template variable names to (env_var_name, default_value)
# Add new variables here - they'll automatically be available as {{VAR_NAME}}

VARIABLES: dict[str, tuple[str, str]] = {
    # Project metadata
    "PROJECT_NAME":        ("PROJECT_NAME", "my-project"),
    "PROJECT_NAME_SNAKE":  ("PROJECT_NAME_SNAKE", "my_project"),
    "PROJECT_NAME_KEBAB":  ("PROJECT_NAME_KEBAB", "my-project"),
    "PROJECT_DESCRIPTION": ("PROJECT_DESCRIPTION", "A new project"),
    "GITHUB_ORG":          ("GITHUB_ORG", "myorg"),

    # Language versions
    "PYTHON_VERSION":      ("PYTHON_VERSION", "3.12"),
    "GO_VERSION":          ("GO_VERSION", "1.22.0"),
    "NODE_VERSION":        ("NODE_VERSION", "20"),
    "RUST_VERSION":        ("RUST_VERSION", "stable"),

    # Infrastructure
    "POSTGRES_VERSION":    ("POSTGRES_VERSION", "16"),
    "REDIS_VERSION":       ("REDIS_VERSION", "7"),
    "DB_NAME":             ("DB_NAME", "app_dev"),
    "DB_USER":             ("DB_USER", "app_user"),
    "DB_PASSWORD":         ("DB_PASSWORD", "dev_password"),

    # Quality settings
    "COVERAGE_THRESHOLD":  ("COVERAGE_THRESHOLD", "80"),
}


def compute_derived_variables(base_vars: dict[str, str]) -> dict[str, str]:
    """
    Compute derived variables from base variables.

    Add new derived variables here. These are computed from other variables
    rather than read directly from environment.

    Args:
        base_vars: Dictionary of base variable values

    Returns:
        Dictionary of derived variable names and values
    """
    derived = {}

    # Python: 3.12 → 312 (for target-version in ruff/pyproject)
    py_ver = base_vars.get("PYTHON_VERSION", "3.12")
    derived["PYTHON_VERSION_NODOT"] = py_ver.replace(".", "")

    # Go: 1.22.0 → 1.22 (go.mod only accepts major.minor)
    go_ver = base_vars.get("GO_VERSION", "1.22.0")
    parts = go_ver.split(".")
    derived["GO_VERSION_SHORT"] = ".".join(parts[:2]) if len(parts) >= 2 else go_ver

    # Rust: stable/nightly/beta → 1.75 (MSRV needs concrete version)
    rust_ver = base_vars.get("RUST_VERSION", "stable")
    if rust_ver in ("stable", "nightly", "beta"):
        derived["RUST_MSRV"] = "1.75"
    else:
        derived["RUST_MSRV"] = rust_ver

    return derived


# -----------------------------------------------------------------------------
# Condition Definitions
# -----------------------------------------------------------------------------
# Maps condition names to evaluation functions
# Add new conditions here - they'll automatically work as {{#IF_CONDITION}}

def _env_is_true(var_name: str) -> Callable[[], bool]:
    """Helper: Returns a function that checks if env var equals 'true'."""
    return lambda: os.environ.get(var_name, "false").lower() == "true"


def _coverage_enabled() -> bool:
    """Check if coverage threshold is greater than 0."""
    try:
        return int(os.environ.get("COVERAGE_THRESHOLD", "0")) > 0
    except ValueError:
        return False


def _has_services() -> bool:
    """Check if any infrastructure service is enabled."""
    return (os.environ.get("INCLUDE_POSTGRES", "false").lower() == "true" or
            os.environ.get("INCLUDE_REDIS", "false").lower() == "true")


# Condition registry: condition_name → callable returning bool
CONDITIONS: dict[str, Callable[[], bool]] = {
    # Languages
    "IF_PYTHON":          _env_is_true("INCLUDE_PYTHON"),
    "IF_GO":              _env_is_true("INCLUDE_GO"),
    "IF_NODE":            _env_is_true("INCLUDE_NODE"),
    "IF_RUST":            _env_is_true("INCLUDE_RUST"),

    # Infrastructure
    "IF_POSTGRES":        _env_is_true("INCLUDE_POSTGRES"),
    "IF_REDIS":           _env_is_true("INCLUDE_REDIS"),
    "IF_HAS_SERVICES":    _has_services,

    # AI workflows
    "IF_AI_SESSIONS":     _env_is_true("INCLUDE_AI_SESSIONS"),
    "IF_AI_PROMPTS":      _env_is_true("INCLUDE_AI_PROMPTS"),

    # Quality & tools
    "IF_QUALITY_CHECKS":  _env_is_true("INCLUDE_QUALITY_CHECKS"),
    "IF_COVERAGE_ENABLED": _coverage_enabled,
    "IF_PRECOMMIT":       _env_is_true("INCLUDE_PRECOMMIT"),
    "IF_PULUMI":          _env_is_true("INCLUDE_PULUMI"),
    "IF_GH_CLI":          _env_is_true("INCLUDE_GH_CLI"),
    "IF_CLAUDE_CODE":     _env_is_true("INCLUDE_CLAUDE_CODE"),
    "IF_INFISICAL":       _env_is_true("INCLUDE_INFISICAL"),
    "IF_GCLOUD":          _env_is_true("INCLUDE_GCLOUD"),
}


# =============================================================================
# CORE ENGINE - Rarely needs modification
# =============================================================================

@dataclass
class TemplateError(Exception):
    """
    Exception raised for template processing errors.

    Attributes:
        message: Error description
        file: Template file path (if known)
        line: Line number where error occurred (if known)
        context: The problematic line content (if known)
    """
    message: str
    file: str | None = None
    line: int | None = None
    context: str | None = None

    def __str__(self) -> str:
        parts = [self.message]
        if self.file:
            parts.append(f"File: {self.file}")
        if self.line:
            parts.append(f"Line: {self.line}")
        if self.context:
            parts.append(f"  → {self.context.strip()}")
        return "\n".join(parts)


class TemplateEngine:
    """
    Template processing engine.

    Handles variable substitution and conditional block processing
    with support for nested conditionals and else blocks.

    Example:
        >>> engine = TemplateEngine()
        >>> result = engine.process_string("Hello {{NAME}}!")
        >>> engine.process_file("input.template", "output.txt")
    """

    def __init__(self) -> None:
        """Initialize the engine with variables from environment."""
        self.variables = self._load_variables()

    def _load_variables(self) -> dict[str, str]:
        """
        Load all variables from environment and compute derived values.

        Returns:
            Complete dictionary of variable names to values
        """
        # Load base variables from environment
        base_vars = {}
        for var_name, (env_name, default) in VARIABLES.items():
            base_vars[var_name] = os.environ.get(env_name, default)

        # Add derived variables
        derived = compute_derived_variables(base_vars)
        base_vars.update(derived)

        return base_vars

    def _evaluate_condition(self, condition_name: str) -> bool:
        """
        Evaluate a condition by name.

        Args:
            condition_name: Name of the condition (e.g., "IF_PYTHON")

        Returns:
            True if condition is met, False otherwise

        Note:
            Unknown conditions evaluate to False with a warning.
        """
        if condition_name in CONDITIONS:
            return CONDITIONS[condition_name]()

        # Unknown condition - warn and return False
        print(f"Warning: Unknown condition '{condition_name}', treating as False",
              file=sys.stderr)
        return False

    def _process_conditionals(self, content: str) -> str:
        """
        Process all conditional blocks in the content.

        Handles:
        - Simple conditionals: {{#IF_X}}...{{/IF_X}}
        - Conditionals with else: {{#IF_X}}...{{#ELSE}}...{{/IF_X}}
        - Nested conditionals (processes innermost first)

        Args:
            content: Template content with conditional blocks

        Returns:
            Content with conditionals resolved
        """
        # Pattern matches {{#IF_X}}...{{/IF_X}} (non-greedy for nesting)
        pattern = r'\{\{#(IF_[A-Z_]+)\}\}(.*?)\{\{/\1\}\}'

        def replace_conditional(match: re.Match) -> str:
            condition_name = match.group(1)
            block_content = match.group(2)

            # Split on {{#ELSE}} if present
            else_parts = re.split(r'\{\{#ELSE\}\}', block_content, maxsplit=1)
            if_content = else_parts[0]
            else_content = else_parts[1] if len(else_parts) > 1 else ""

            # Evaluate and select appropriate content
            if self._evaluate_condition(condition_name):
                result = if_content
            else:
                result = else_content

            # Recursively process nested conditionals
            return self._process_conditionals(result)

        # Process conditionals (DOTALL flag for multiline content)
        # Iterate to handle nested conditionals (innermost first)
        max_iterations = 20  # Safety limit
        for _ in range(max_iterations):
            new_content = re.sub(pattern, replace_conditional, content, flags=re.DOTALL)
            if new_content == content:
                break
            content = new_content

        return content

    def _process_variables(self, content: str) -> str:
        """
        Substitute all {{VAR}} placeholders with values.

        Args:
            content: Template content with variable placeholders

        Returns:
            Content with variables substituted

        Note:
            - Only matches {{UPPER_CASE_VAR}} pattern
            - Does not match GitHub Actions syntax ${{ }}
            - Unknown variables are left unchanged
        """
        def replace_variable(match: re.Match) -> str:
            var_name = match.group(1)
            return self.variables.get(var_name, match.group(0))

        # Match {{VAR}} but not ${{ (GitHub Actions)
        pattern = r'(?<!\$)\{\{([A-Z][A-Z0-9_]*)\}\}'
        return re.sub(pattern, replace_variable, content)

    def process_string(self, content: str) -> str:
        """
        Process a template string.

        Args:
            content: Template content as string

        Returns:
            Processed content with conditionals and variables resolved
        """
        # Order matters: conditionals first (they may contain variables)
        content = self._process_conditionals(content)
        content = self._process_variables(content)

        # Normalize trailing whitespace: ensure exactly one trailing newline
        # This prevents pre-commit hooks from failing due to missing EOF newline
        content = content.rstrip() + "\n"

        return content

    def process_file(self, input_path: str | Path, output_path: str | Path) -> None:
        """
        Process a template file and write the result.

        Args:
            input_path: Path to the template file
            output_path: Path for the output file

        Raises:
            TemplateError: If the template file cannot be read or processed
        """
        input_path = Path(input_path)
        output_path = Path(output_path)

        # Read template
        if not input_path.exists():
            raise TemplateError("Template file not found", file=str(input_path))

        try:
            content = input_path.read_text()
        except Exception as e:
            raise TemplateError(f"Failed to read template: {e}", file=str(input_path)) from e

        # Process
        result = self.process_string(content)

        # Write output
        try:
            output_path.parent.mkdir(parents=True, exist_ok=True)
            output_path.write_text(result)
        except Exception as e:
            raise TemplateError(f"Failed to write output: {e}", file=str(output_path)) from e


# =============================================================================
# CLI INTERFACE
# =============================================================================

def main() -> int:
    """
    Command-line interface for the template engine.

    Usage:
        python3 template_engine.py <input_template> <output_file>

    Returns:
        0 on success, 1 on error
    """
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <input_template> <output_file>", file=sys.stderr)
        print(__doc__, file=sys.stderr)
        return 1

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    try:
        engine = TemplateEngine()
        engine.process_file(input_file, output_file)
        return 0
    except TemplateError as e:
        print(f"Template Error: {e}", file=sys.stderr)
        return 1
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
