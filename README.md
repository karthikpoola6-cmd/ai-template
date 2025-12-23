# Codespaces AI Development Template

A production-ready development environment with multi-language support, AI-assisted workflows, and flexible quality controls. Get from zero to coding in under 5 minutes.

## 30-Second Quick Start

**Using GitHub Codespaces:**

1. Click **"Use this template"** → **"Create a new repository"**
2. Click **"Code"** → **"Codespaces"** → **"Create codespace"**
3. Run: `./bootstrap.sh --quick`
4. Run: `make doctor` to verify setup

That's it. You're ready to code.

---

## Table of Contents

- [What You Get](#what-you-get)
- [Getting Started](#getting-started)
- [Your First 10 Minutes](#your-first-10-minutes)
- [Daily Workflow](#daily-workflow)
- [Configuration](#configuration)
- [Command Reference](#command-reference)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)
- [Template Development](#template-development)

---

## What You Get

After bootstrap, your project includes:

| Feature | Description |
|---------|-------------|
| **Multi-Language Support** | Python, Go, Node.js, Rust - enable what you need |
| **Quality Presets** | Switch between strict/standard/relaxed with one command |
| **AI Development Workflows** | Session management, checkpoints, and prompts |
| **CI/CD Pipelines** | Pre-configured GitHub Actions that read your config |
| **Single Source of Truth** | One `.project.yaml` controls everything |
| **Diagnostic Tools** | `make doctor` catches issues before they slow you down |

### Project Structure

```
your-project/
├── src/                      # Your source code goes here
├── tests/                    # Your tests go here
├── .project.yaml             # Single config file for everything
├── Makefile                  # All commands in one place
├── .project/                 # Framework tooling (managed for you)
├── .ai/                      # AI prompts and session history
└── .github/workflows/        # CI/CD (auto-generated)
```

---

## Getting Started

### Option 1: GitHub Codespaces (Recommended)

The fastest path - everything is pre-installed.

```bash
# After creating your Codespace, choose one:

./bootstrap.sh --quick              # Python only, zero prompts
./bootstrap.sh                      # Interactive, choose your stack
./bootstrap.sh --python --go        # Specific languages
./bootstrap.sh --all                # Everything enabled
```

### Option 2: Local Development

```bash
# Prerequisites: Python 3.10+
pip install pyyaml

# Clone and bootstrap
git clone <your-repo-url>
cd <your-repo>
./bootstrap.sh
```

### Verify Your Setup

Always run this after bootstrap:

```bash
make doctor    # Checks toolchains, config, and dependencies
```

If doctor reports issues, it tells you exactly how to fix them.

---

## Your First 10 Minutes

After bootstrap, try these commands to explore your new project:

```bash
# 1. See your configuration
make info

# 2. See all available commands
make help

# 3. Run tests (if you've added any)
make test

# 4. Check code quality
make quality

# 5. Start an AI-assisted session (optional)
make session-start
```

### Quick Config Changes

```bash
# Too strict? Relax quality checks for prototyping
make quality-relaxed

# Need Go? Add it
make lang-add LANG=go

# See what changed
make info
```

---

## Daily Workflow

### Standard Development Flow

```bash
# Start your day
make session-start          # Shows last checkpoint, sets context

# Code, test, repeat
make test                   # Run tests
make quality                # Check quality
make fix                    # Auto-fix issues

# Before committing
make check                  # Full validation (test + quality + validate)

# Commit and push
make session-commit         # Commit with quality checks
make session-push           # Push (skips checks if tree is clean)

# Create a PR
make session-pr             # Auto-generates PR content
```

### Useful Shortcuts

| What you want | Command |
|---------------|---------|
| Run quick tests only | `make test-unit` |
| Format all code | `make format` |
| Fix all auto-fixable issues | `make fix` |
| Skip quality checks (emergency) | `make session-commit SKIP_VERIFY=1` |

---

## Configuration

### The Config File

Everything is controlled by `.project.yaml`:

```yaml
project:
  name: "my-project"
  description: "A new project"

languages:
  python:
    enabled: true
    version: "3.12"
    quality:
      coverage: 80        # Coverage threshold %
      lint: true
      typecheck: true
      format: true
  go:
    enabled: false
    # ... similar structure

precommit: true

infrastructure:
  postgres:
    enabled: false
  redis:
    enabled: false
```

### Quality Presets

Don't want to tweak individual settings? Use presets:

| Preset | Coverage | Best For |
|--------|----------|----------|
| `make quality-strict` | 90% | Production code, CI enforcement |
| `make quality-standard` | 80% | Regular development (default) |
| `make quality-relaxed` | 50% | Rapid prototyping, experiments |
| `make quality-off` | 0% | Emergencies, debugging |

### Managing Languages

```bash
make lang-list              # See what's enabled
make lang-add LANG=go       # Enable Go
make lang-remove LANG=rust  # Disable Rust
make sync                   # Apply changes to config files
```

### Editing Config

```bash
make config                 # Interactive editor
# OR edit .project.yaml directly, then:
make sync                   # Sync changes to language files
```

---

## Command Reference

### Essential Commands

| Command | Description |
|---------|-------------|
| `make help` | Show all available commands |
| `make info` | Display project configuration dashboard |
| `make doctor` | Diagnose setup issues |
| `make check` | Run all validations before commit |
| `make fix` | Auto-fix all fixable issues |

### Testing

| Command | Description |
|---------|-------------|
| `make test` | Run all tests |
| `make test-unit` | Run only unit tests (fast) |
| `make test-coverage` | Generate detailed coverage reports |

### Code Quality

| Command | Description |
|---------|-------------|
| `make quality` | Run all quality checks |
| `make lint` | Lint all code |
| `make format` | Format all code |
| `make quality-fix` | Auto-fix quality issues |

### AI-Assisted Development

| Command | Description |
|---------|-------------|
| `make session-start` | Start development session with context |
| `make session-end` | End session, create checkpoint |
| `make session-commit` | Commit with quality verification |
| `make session-pr` | Create PR with auto-generated content |
| `make ai-history` | View recent session history |

### Configuration

| Command | Description |
|---------|-------------|
| `make config` | Interactive config editor |
| `make sync` | Sync .project.yaml to language files |
| `make sync-preview` | Preview sync changes (dry run) |
| `make lang-list` | List languages and status |
| `make lang-add LANG=x` | Enable a language |
| `make lang-remove LANG=x` | Disable a language |

---

## Examples

Need a starting point? Check out the [examples/](./examples/) directory for minimal, runnable code patterns:

| Example | Description |
|---------|-------------|
| [python-cli](./examples/python-cli/) | Command-line tool with argparse |
| [python-api](./examples/python-api/) | REST API with FastAPI |
| [go-service](./examples/go-service/) | HTTP service with standard library |

These are **reference implementations**, not scaffolding. Copy what you need:

```bash
# Example: Start with the Python CLI pattern
cp -r examples/python-cli/src/* src/
cp -r examples/python-cli/tests/* tests/
make test
```

---

## Troubleshooting

### First Step: Run Doctor

```bash
make doctor
```

This diagnoses most issues and tells you how to fix them.

### Common Issues

<details>
<summary><strong>Bootstrap fails with "PyYAML not found"</strong></summary>

```bash
pip install pyyaml
```
</details>

<details>
<summary><strong>"command not found" errors when running make commands</strong></summary>

Install the required toolchains:

```bash
make setup          # Interactive setup
make doctor         # Verify installation
```
</details>

<details>
<summary><strong>Coverage check fails but tests pass</strong></summary>

Your coverage is below the threshold. Options:

```bash
make info                    # Check current threshold
make quality-relaxed         # Lower to 50%
make quality-off             # Disable checks entirely
```

Or edit `.project.yaml`:

```yaml
languages:
  python:
    quality:
      coverage: 70    # Set your desired %
```
</details>

<details>
<summary><strong>"pre-commit hook not found" warning</strong></summary>

```bash
pip install pre-commit
pre-commit install
```
</details>

<details>
<summary><strong>Language version mismatch</strong></summary>

Either install the correct version, or update `.project.yaml` to match:

```yaml
languages:
  python:
    version: "3.11"   # Match your installed version
```
</details>

<details>
<summary><strong>Config changes not taking effect</strong></summary>

After editing `.project.yaml`:

```bash
make sync            # Apply changes
make sync-preview    # Preview first (dry run)
```
</details>

<details>
<summary><strong>"No rule to make target" error</strong></summary>

The project may not be bootstrapped:

```bash
./bootstrap.sh
```
</details>

<details>
<summary><strong>CI fails but local tests pass</strong></summary>

```bash
make doctor          # Verify setup matches CI
make check           # Run full CI-equivalent locally
```

Common causes:
- Missing `make sync` after config changes
- Different language versions
- Uncommitted config changes
</details>

### Getting Help

- Run `make help` for command reference
- Run `make doctor` for diagnostics
- Check [Issues](https://github.com/your-repo/issues) for known problems

---

## Template Development

For contributors who want to modify the template itself.

### Template Location

```
.template/
├── .project/                 # Framework tooling (copied to projects)
├── .devcontainer/            # Container templates
├── .github/workflows/        # CI templates
├── configs/                  # Language config templates
├── scripts/bootstrap/        # Template processing engine
└── Makefile                  # Project Makefile template
```

### Template Syntax

**Variables:** `{{VARIABLE_NAME}}`

```dockerfile
FROM python:{{PYTHON_VERSION}}-slim
```

**Conditionals:** `{{#IF_CONDITION}}...{{/IF_CONDITION}}`

```yaml
{{#IF_POSTGRES}}
  db:
    image: postgres:{{POSTGRES_VERSION}}-alpine
{{/IF_POSTGRES}}
```

**Else blocks:** `{{#IF_X}}...{{#ELSE}}...{{/IF_X}}`

### Adding New Features

1. Add templates to `.template/`
2. Update `scripts/bootstrap/template_engine.py` if new variables needed
3. Update `bootstrap.sh` for new prompts
4. Update `.template/scripts/bootstrap/apply-config.sh` for file processing
5. Test with `./scripts/validate-templates.sh`

See [docs/ADDING_LANGUAGES.md](docs/ADDING_LANGUAGES.md) for detailed guide.

---

## License

MIT License
