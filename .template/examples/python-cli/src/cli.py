"""Command-line interface.

Entry point for the CLI application.
Run with: python -m src.cli <command>
"""

import argparse
import sys

from . import commands


def create_parser() -> argparse.ArgumentParser:
    """Create the argument parser with all subcommands."""
    parser = argparse.ArgumentParser(
        prog="cli",
        description="Example CLI application",
    )
    parser.add_argument(
        "--version",
        action="version",
        version=f"%(prog)s {commands.version()}",
    )

    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    # greet command
    greet_parser = subparsers.add_parser("greet", help="Greet someone")
    greet_parser.add_argument(
        "--name",
        type=str,
        default="World",
        help="Name to greet (default: World)",
    )

    # add command
    add_parser = subparsers.add_parser("add", help="Add two numbers")
    add_parser.add_argument("a", type=int, help="First number")
    add_parser.add_argument("b", type=int, help="Second number")

    return parser


def main(argv: list[str] | None = None) -> int:
    """Main entry point.

    Args:
        argv: Command-line arguments (defaults to sys.argv[1:]).

    Returns:
        Exit code (0 for success).
    """
    parser = create_parser()
    args = parser.parse_args(argv)

    if args.command is None:
        parser.print_help()
        return 0

    if args.command == "greet":
        print(commands.greet(args.name))
    elif args.command == "add":
        result = commands.add(args.a, args.b)
        print(f"{args.a} + {args.b} = {result}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
