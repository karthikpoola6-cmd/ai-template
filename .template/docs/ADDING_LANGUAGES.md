# Adding a New Language to the Template

This guide documents the process of adding support for a new programming language to the codespaces AI template.

## Template Engine

The template system uses a Python-based engine (`scripts/bootstrap/template_engine.py`) that supports:

- **Variables**: `{{VAR_NAME}}` - Substituted with values
- **Conditionals**: `{{#IF_X}}...{{/IF_X}}` - Include block if condition is true
- **Else blocks**: `{{#IF_X}}...{{#ELSE}}...{{/IF_X}}` - If/else logic
- **Nested conditionals**: Conditionals can be nested

## Overview

Adding a new language requires modifications to several files:

| File | Purpose |
|------|---------|
| `scripts/bootstrap/bootstrap.sh` | Add user prompts for the language |
| `scripts/bootstrap/template_engine.py` | Add variables and conditions |
| `.template/.github/workflows/ci.yml.template` | Add CI test job |
| `.template/.github/workflows/quality.yml.template` | Add linting job |
| `.template/.pre-commit-config.yaml.template` | Add pre-commit hooks |
| `.template/configs/<lang>/` | Language-specific config templates |
| `scripts/validate-templates.sh` | Add validation for new templates |

## Step-by-Step Guide

### 1. Add Bootstrap Prompts

Edit `scripts/bootstrap/bootstrap.sh`:

```bash
# In the LANGUAGES section, add:
prompt_yes_no "Include <Language>?" "n" INCLUDE_<LANG>

# If version selection is needed:
[ "$INCLUDE_<LANG>" = true ] && prompt_with_default "<Language> version" "$<LANG>_DEFAULT" <LANG>_VERSION
```

Add the export at the bottom:
```bash
export INCLUDE_<LANG> <LANG>_VERSION
```

### 2. Add Variables and Conditions

Edit `scripts/bootstrap/template_engine.py`:

#### Add variables to the VARIABLES dict:
```python
VARIABLES: dict[str, tuple[str, str]] = {
    # ... existing variables

    # Add your language version
    "<LANG>_VERSION":      ("<LANG>_VERSION", "1.0"),
}
```

#### Add derived variables if needed:
```python
def compute_derived_variables(base_vars: dict[str, str]) -> dict[str, str]:
    # ... existing derivations

    # Example: derive short version
    lang_ver = base_vars.get("<LANG>_VERSION", "1.0")
    derived["<LANG>_VERSION_SHORT"] = lang_ver.split(".")[0]

    return derived
```

#### Add condition to the CONDITIONS dict:
```python
CONDITIONS: dict[str, Callable[[], bool]] = {
    # ... existing conditions

    # Add your language condition
    "IF_<LANG>":          _env_is_true("INCLUDE_<LANG>"),
}
```

#### Add config file generation in apply-config.sh:
```bash
if [ "$INCLUDE_<LANG>" = "true" ]; then
    echo -e "${CYAN}Generating <Language> configuration...${RESET}"
    process_template "$TEMPLATE_DIR/configs/<lang>/<file>.template" "./<file>"
    mkdir -p <directories>
    echo -e "  ${GREEN}✓${RESET} Generated: <Language> configs"
    echo ""
fi
```

### 3. Create Config Templates

Create directory: `.template/configs/<lang>/`

Create language-specific config files with template variables:
- Use `{{PROJECT_NAME}}`, `{{PROJECT_NAME_SNAKE}}` for project names
- Use `{{<LANG>_VERSION}}` for version
- Use `{{GITHUB_ORG}}` for repository paths

Example `.template/configs/<lang>/config.template`:
```
# {{PROJECT_NAME}} - <Language> Configuration
version = "{{<LANG>_VERSION}}"
```

### 4. Add CI Workflow Job

Edit `.template/.github/workflows/ci.yml.template`:

```yaml
{{#IF_<LANG>}}
  test-<lang>:
    name: <Language> {{<LANG>_VERSION}} Tests
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up <Language> {{<LANG>_VERSION}}
        uses: <setup-action>
        with:
          <lang>-version: "{{<LANG>_VERSION}}"

      - name: Install dependencies
        run: <install-command>

      - name: Load quality configuration
        id: quality
        run: |
          if [ -f .quality.env ]; then
            source .quality.env
          fi
          echo "coverage_threshold=${COVERAGE_THRESHOLD:-{{COVERAGE_THRESHOLD}}}" >> $GITHUB_OUTPUT
          echo "skip_coverage=${SKIP_COVERAGE_CHECK:-false}" >> $GITHUB_OUTPUT

      - name: Run tests
        run: |
          THRESHOLD=${{ steps.quality.outputs.coverage_threshold }}
          SKIP_COV=${{ steps.quality.outputs.skip_coverage }}
          # Add coverage threshold logic based on language tooling

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          file: ./<coverage-file>
          flags: <lang>
          name: <lang>-{{<LANG>_VERSION}}

{{/IF_<LANG>}}
```

### 5. Add Quality Workflow Job

Edit `.template/.github/workflows/quality.yml.template`:

```yaml
{{#IF_<LANG>}}
{{#IF_QUALITY_CHECKS}}
  lint-<lang>:
    name: <Language> Linting & Formatting
    runs-on: ubuntu-latest
    if: vars.SKIP_QUALITY_CHECKS != 'true'

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up <Language> {{<LANG>_VERSION}}
        uses: <setup-action>
        with:
          <lang>-version: "{{<LANG>_VERSION}}"

      - name: Install linting tools
        run: <install-linters>

      - name: Run linter
        run: <lint-command>

      - name: Check formatting
        run: <format-check-command>

{{/IF_QUALITY_CHECKS}}
{{/IF_<LANG>}}
```

### 6. Add Pre-commit Hooks (Optional)

Edit `.template/.pre-commit-config.yaml.template`:

```yaml
{{#IF_<LANG>}}
  - repo: <linter-repo>
    rev: <version>
    hooks:
      - id: <hook-id>
{{/IF_<LANG>}}
```

### 7. Update Validation Script

Edit `scripts/validate-templates.sh`:

#### Add test exports:
```bash
export INCLUDE_<LANG>="true"
export <LANG>_VERSION="1.0"
```

#### Add templates to validation arrays:
```bash
# For YAML configs:
yaml_templates+=(
    ".template/configs/<lang>/<file>.yml.template"
)

# For TOML configs:
toml_templates+=(
    ".template/configs/<lang>/<file>.toml.template"
)

# For JSON configs:
json_templates+=(
    ".template/configs/<lang>/<file>.json.template"
)
```

### 8. Test the Changes

```bash
# Run template validation
./scripts/validate-templates.sh

# Test full bootstrap
mkdir /tmp/test-<lang>-project && cd /tmp/test-<lang>-project
export PROJECT_NAME="test-<lang>-app" \
       INCLUDE_<LANG>="true" \
       <LANG>_VERSION="1.0" \
       # ... other required exports
cp -r /path/to/template/.template .
bash .template/scripts/bootstrap/apply-config.sh

# Verify generated files
cat <config-file>
cat .github/workflows/ci.yml
```

## Checklist

When adding a new language, verify:

- [ ] Bootstrap prompts work correctly
- [ ] Config files generate with correct values
- [ ] CI workflow job is syntactically valid
- [ ] Quality workflow job is syntactically valid
- [ ] Pre-commit hooks work (if added)
- [ ] Validation script passes
- [ ] Coverage threshold reads from `.quality.env`
- [ ] `SKIP_QUALITY_CHECKS` variable is respected

## Template Variables Reference

| Variable | Description | Example |
|----------|-------------|---------|
| `{{PROJECT_NAME}}` | Project name (original) | `my-project` |
| `{{PROJECT_NAME_SNAKE}}` | Snake case | `my_project` |
| `{{PROJECT_NAME_KEBAB}}` | Kebab case | `my-project` |
| `{{GITHUB_ORG}}` | GitHub org/user | `myorg` |
| `{{COVERAGE_THRESHOLD}}` | Coverage % | `80` |

## Conditional Blocks Reference

| Block | True When |
|-------|-----------|
| `{{#IF_<LANG>}}...{{/IF_<LANG>}}` | `INCLUDE_<LANG>=true` |
| `{{#IF_QUALITY_CHECKS}}...{{/IF_QUALITY_CHECKS}}` | `INCLUDE_QUALITY_CHECKS=true` |
| `{{#IF_COVERAGE_ENABLED}}...{{/IF_COVERAGE_ENABLED}}` | `COVERAGE_THRESHOLD > 0` |
