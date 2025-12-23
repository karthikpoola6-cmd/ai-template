#!/bin/bash
set -e

# Colors
CYAN='\033[36m'
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[1;33m'
DIM='\033[2m'
RESET='\033[0m'

# Script directory (for calling sibling scripts)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create tmp directory for reports
mkdir -p tmp/reports

REPORT_FILE="tmp/reports/quality-report.md"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
FAILED=0

# Helper to read config
read_config() {
    local path="$1"
    local default="$2"
    if [ -f ".project.yaml" ] && command -v python3 &> /dev/null; then
        python3 -c "
import yaml
try:
    with open('.project.yaml') as f:
        c = yaml.safe_load(f)
    keys = '$path'.split('.')
    val = c
    for k in keys:
        val = val.get(k, {}) if isinstance(val, dict) else {}
    print('true' if val is True else ('false' if val is False else '$default'))
except:
    print('$default')
" 2>/dev/null || echo "$default"
    else
        echo "$default"
    fi
}

# Read enabled languages from config
PYTHON_ENABLED=$(read_config "languages.python.enabled" "false")
GO_ENABLED=$(read_config "languages.go.enabled" "false")
NODE_ENABLED=$(read_config "languages.node.enabled" "false")
RUST_ENABLED=$(read_config "languages.rust.enabled" "false")

# Start report
cat > "$REPORT_FILE" << EOF
# Quality Report

**Generated:** $TIMESTAMP

---

EOF

echo -e "${CYAN}🔍 Running Quality Checks${RESET}"
echo ""

# ============================================================================
# Format Checks (sync with pre-commit)
# ============================================================================

echo "## Format Checks" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Go format check
echo "### Go Format" >> "$REPORT_FILE"
if [ "$GO_ENABLED" = "true" ]; then
    if find . -name "*.go" -type f -not -path "./v0/*" -not -path "./.git/*" -not -path "./.template/*" | grep -q .; then
        echo -e "${CYAN}Checking Go formatting...${RESET}"
        UNFORMATTED=$(gofmt -l $(find . -name "*.go" -type f -not -path "./v0/*" -not -path "./.git/*" -not -path "./.template/*") 2>/dev/null || true)
        if [ -z "$UNFORMATTED" ]; then
            echo "✅ **PASSED**" >> "$REPORT_FILE"
            echo -e "${GREEN}✓${RESET} Go format check passed"
        else
            echo "❌ **FAILED** - Files need formatting:" >> "$REPORT_FILE"
            echo '```' >> "$REPORT_FILE"
            echo "$UNFORMATTED" >> "$REPORT_FILE"
            echo '```' >> "$REPORT_FILE"
            echo -e "${RED}✗${RESET} Go format check failed"
            FAILED=1
        fi
    else
        echo "_No Go files found_" >> "$REPORT_FILE"
    fi
else
    echo "_Go not enabled_" >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# Python format check (ruff format)
echo "### Python Format" >> "$REPORT_FILE"
if [ "$PYTHON_ENABLED" = "true" ]; then
    if find . -name "*.py" -type f -not -path "./v0/*" -not -path "./.git/*" -not -path "./.venv/*" -not -path "./venv/*" -not -path "./.template/*" | grep -q .; then
        echo -e "${CYAN}Checking Python formatting...${RESET}"
        if command -v ruff &> /dev/null; then
            if ruff format --check . --exclude ".template,.venv,venv,v0" 2>/dev/null; then
                echo "✅ **PASSED**" >> "$REPORT_FILE"
                echo -e "${GREEN}✓${RESET} Python format check passed"
            else
                echo "❌ **FAILED**" >> "$REPORT_FILE"
                echo -e "${RED}✗${RESET} Python format check failed"
                FAILED=1
            fi
        else
            echo "⚠️ **ruff not installed**" >> "$REPORT_FILE"
            echo -e "${YELLOW}!${RESET} ruff not installed (run: pip install ruff)"
        fi
    else
        echo "_No Python files found_" >> "$REPORT_FILE"
    fi
else
    echo "_Python not enabled_" >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# Node.js format check (prettier)
echo "### Node.js Format" >> "$REPORT_FILE"
if [ "$NODE_ENABLED" = "true" ]; then
    if find . \( -name "*.ts" -o -name "*.js" -o -name "*.tsx" -o -name "*.jsx" \) -type f -not -path "./node_modules/*" -not -path "./.git/*" -not -path "./.template/*" 2>/dev/null | grep -q .; then
        echo -e "${CYAN}Checking Node.js formatting...${RESET}"
        PRETTIER_CMD=""
        if command -v prettier &> /dev/null; then
            PRETTIER_CMD="prettier"
        elif [ -f "node_modules/.bin/prettier" ]; then
            PRETTIER_CMD="./node_modules/.bin/prettier"
        fi
        if [ -n "$PRETTIER_CMD" ]; then
            if $PRETTIER_CMD --check "**/*.{js,ts,jsx,tsx}" 2>/dev/null; then
                echo "✅ **PASSED**" >> "$REPORT_FILE"
                echo -e "${GREEN}✓${RESET} Node.js format check passed"
            else
                echo "❌ **FAILED**" >> "$REPORT_FILE"
                echo -e "${RED}✗${RESET} Node.js format check failed"
                FAILED=1
            fi
        else
            echo "⚠️ **prettier not installed**" >> "$REPORT_FILE"
            echo -e "${YELLOW}!${RESET} prettier not installed (run: npm install -D prettier)"
        fi
    else
        echo "_No JS/TS files found_" >> "$REPORT_FILE"
    fi
else
    echo "_Node.js not enabled_" >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# Rust format check
echo "### Rust Format" >> "$REPORT_FILE"
if [ "$RUST_ENABLED" = "true" ]; then
    if find . -name "*.rs" -type f -not -path "./target/*" -not -path "./.git/*" -not -path "./.template/*" | grep -q .; then
        echo -e "${CYAN}Checking Rust formatting...${RESET}"
        if command -v cargo &> /dev/null; then
            if cargo fmt -- --check 2>/dev/null; then
                echo "✅ **PASSED**" >> "$REPORT_FILE"
                echo -e "${GREEN}✓${RESET} Rust format check passed"
            else
                echo "❌ **FAILED**" >> "$REPORT_FILE"
                echo -e "${RED}✗${RESET} Rust format check failed"
                FAILED=1
            fi
        else
            echo "⚠️ **cargo not installed**" >> "$REPORT_FILE"
            echo -e "${YELLOW}!${RESET} cargo not installed"
        fi
    else
        echo "_No Rust files found_" >> "$REPORT_FILE"
    fi
else
    echo "_Rust not enabled_" >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# ============================================================================
# File Validation (sync with pre-commit universal hooks)
# ============================================================================

echo "## File Validation" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# YAML validation
echo "### YAML Files" >> "$REPORT_FILE"
YAML_FILES=$(find . -name "*.yaml" -o -name "*.yml" -type f -not -path "./.git/*" -not -path "./node_modules/*" -not -path "./.template/*" 2>/dev/null | head -100)
if [ -n "$YAML_FILES" ]; then
    echo -e "${CYAN}Validating YAML files...${RESET}"
    YAML_FAILED=0
    if command -v python3 &> /dev/null; then
        for f in $YAML_FILES; do
            if ! python3 -c "import yaml; yaml.safe_load(open('$f'))" 2>/dev/null; then
                echo "  Invalid: $f" >> "$REPORT_FILE"
                YAML_FAILED=1
            fi
        done
        if [ $YAML_FAILED -eq 0 ]; then
            echo "✅ **PASSED**" >> "$REPORT_FILE"
            echo -e "${GREEN}✓${RESET} YAML validation passed"
        else
            echo "❌ **FAILED**" >> "$REPORT_FILE"
            echo -e "${RED}✗${RESET} YAML validation failed"
            FAILED=1
        fi
    else
        echo "⚠️ **python3 not available**" >> "$REPORT_FILE"
    fi
else
    echo "_No YAML files found_" >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# JSON validation
echo "### JSON Files" >> "$REPORT_FILE"
JSON_FILES=$(find . -name "*.json" -type f -not -path "./.git/*" -not -path "./node_modules/*" -not -path "./.template/*" 2>/dev/null | head -100)
if [ -n "$JSON_FILES" ]; then
    echo -e "${CYAN}Validating JSON files...${RESET}"
    JSON_FAILED=0
    if command -v python3 &> /dev/null; then
        for f in $JSON_FILES; do
            if ! python3 -c "import json; json.load(open('$f'))" 2>/dev/null; then
                echo "  Invalid: $f" >> "$REPORT_FILE"
                JSON_FAILED=1
            fi
        done
        if [ $JSON_FAILED -eq 0 ]; then
            echo "✅ **PASSED**" >> "$REPORT_FILE"
            echo -e "${GREEN}✓${RESET} JSON validation passed"
        else
            echo "❌ **FAILED**" >> "$REPORT_FILE"
            echo -e "${RED}✗${RESET} JSON validation failed"
            FAILED=1
        fi
    else
        echo "⚠️ **python3 not available**" >> "$REPORT_FILE"
    fi
else
    echo "_No JSON files found_" >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# TOML validation
echo "### TOML Files" >> "$REPORT_FILE"
TOML_FILES=$(find . -name "*.toml" -type f -not -path "./.git/*" -not -path "./node_modules/*" -not -path "./.template/*" -not -path "./target/*" 2>/dev/null | head -100)
if [ -n "$TOML_FILES" ]; then
    echo -e "${CYAN}Validating TOML files...${RESET}"
    TOML_FAILED=0
    if command -v python3 &> /dev/null && python3 -c "import tomllib" 2>/dev/null; then
        for f in $TOML_FILES; do
            if ! python3 -c "import tomllib; tomllib.load(open('$f', 'rb'))" 2>/dev/null; then
                echo "  Invalid: $f" >> "$REPORT_FILE"
                TOML_FAILED=1
            fi
        done
        if [ $TOML_FAILED -eq 0 ]; then
            echo "✅ **PASSED**" >> "$REPORT_FILE"
            echo -e "${GREEN}✓${RESET} TOML validation passed"
        else
            echo "❌ **FAILED**" >> "$REPORT_FILE"
            echo -e "${RED}✗${RESET} TOML validation failed"
            FAILED=1
        fi
    else
        echo "⚠️ **tomllib not available (Python 3.11+)**" >> "$REPORT_FILE"
        echo -e "${YELLOW}!${RESET} TOML validation skipped (requires Python 3.11+)"
    fi
else
    echo "_No TOML files found_" >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# Large files check
echo "### Large Files" >> "$REPORT_FILE"
echo -e "${CYAN}Checking for large files...${RESET}"
LARGE_FILES=$(find . -type f -size +1M -not -path "./.git/*" -not -path "./node_modules/*" -not -path "./.template/*" -not -path "./target/*" -not -path "./.venv/*" 2>/dev/null | head -20)
if [ -n "$LARGE_FILES" ]; then
    echo "⚠️ **WARNING** - Large files detected (>1MB):" >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"
    echo "$LARGE_FILES" >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"
    echo -e "${YELLOW}!${RESET} Large files detected (consider adding to .gitignore)"
else
    echo "✅ **PASSED**" >> "$REPORT_FILE"
    echo -e "${GREEN}✓${RESET} No large files detected"
fi
echo "" >> "$REPORT_FILE"

# Merge conflict markers check
echo "### Merge Conflicts" >> "$REPORT_FILE"
echo -e "${CYAN}Checking for merge conflict markers...${RESET}"
CONFLICT_FILES=$(grep -rl "^<<<<<<< \|^=======$\|^>>>>>>> " . --include="*.py" --include="*.go" --include="*.js" --include="*.ts" --include="*.yaml" --include="*.yml" --include="*.json" --include="*.md" 2>/dev/null | grep -v ".git" | grep -v "node_modules" | grep -v ".template" | head -20 || true)
if [ -n "$CONFLICT_FILES" ]; then
    echo "❌ **FAILED** - Merge conflict markers found:" >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"
    echo "$CONFLICT_FILES" >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"
    echo -e "${RED}✗${RESET} Merge conflict markers found"
    FAILED=1
else
    echo "✅ **PASSED**" >> "$REPORT_FILE"
    echo -e "${GREEN}✓${RESET} No merge conflict markers"
fi
echo "" >> "$REPORT_FILE"

# Private key detection
echo "### Private Keys" >> "$REPORT_FILE"
echo -e "${CYAN}Checking for private keys...${RESET}"
PRIVATE_KEY_FILES=$(grep -rl "BEGIN.*PRIVATE KEY" . 2>/dev/null | grep -v ".git" | grep -v "node_modules" | grep -v ".template" | grep -v ".venv" | head -20 || true)
if [ -n "$PRIVATE_KEY_FILES" ]; then
    echo "❌ **FAILED** - Private keys detected:" >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"
    echo "$PRIVATE_KEY_FILES" >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"
    echo -e "${RED}✗${RESET} Private keys detected - DO NOT COMMIT"
    FAILED=1
else
    echo "✅ **PASSED**" >> "$REPORT_FILE"
    echo -e "${GREEN}✓${RESET} No private keys detected"
fi
echo "" >> "$REPORT_FILE"

# ============================================================================
# Linting Checks
# ============================================================================

# Go linting
echo "## Go Linting" >> "$REPORT_FILE"
if [ "$GO_ENABLED" = "true" ]; then
    if find . -name "*.go" -type f -not -path "./v0/*" -not -path "./.git/*" -not -path "./.template/*" | grep -q .; then
        echo -e "${CYAN}Linting Go code...${RESET}"
        if "$SCRIPT_DIR/lint-go.sh" 2>&1 | tee /tmp/go-lint.log; then
            echo "✅ **PASSED**" >> "$REPORT_FILE"
            echo -e "${GREEN}✓${RESET} Go linting passed"
        else
            echo "❌ **FAILED**" >> "$REPORT_FILE"
            echo -e "${RED}✗${RESET} Go linting failed"
            FAILED=1
        fi
    else
        echo "_No Go files found_" >> "$REPORT_FILE"
        echo -e "${DIM}○ Go enabled but no .go files found${RESET}"
    fi
else
    echo "_Go not enabled_" >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# Python linting
echo "## Python Linting" >> "$REPORT_FILE"
if [ "$PYTHON_ENABLED" = "true" ]; then
    if find . -name "*.py" -type f -not -path "./v0/*" -not -path "./.git/*" -not -path "./.venv/*" -not -path "./venv/*" -not -path "./.template/*" | grep -q .; then
        echo -e "${CYAN}Linting Python code...${RESET}"
        if "$SCRIPT_DIR/lint-python.sh" 2>&1 | tee /tmp/python-lint.log; then
            echo "✅ **PASSED**" >> "$REPORT_FILE"
            echo -e "${GREEN}✓${RESET} Python linting passed"
        else
            echo "❌ **FAILED**" >> "$REPORT_FILE"
            echo -e "${RED}✗${RESET} Python linting failed"
            FAILED=1
        fi
    else
        echo "_No Python files found_" >> "$REPORT_FILE"
        echo -e "${DIM}○ Python enabled but no .py files found${RESET}"
    fi
else
    echo "_Python not enabled_" >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# Node.js linting
echo "## Node.js Linting" >> "$REPORT_FILE"
if [ "$NODE_ENABLED" = "true" ]; then
    if find . \( -name "*.ts" -o -name "*.js" \) -type f -not -path "./node_modules/*" -not -path "./.git/*" -not -path "./.template/*" 2>/dev/null | grep -q .; then
        echo -e "${CYAN}Linting Node.js code...${RESET}"
        if command -v eslint &> /dev/null || [ -f "node_modules/.bin/eslint" ]; then
            ESLINT_CMD="eslint"
            [ -f "node_modules/.bin/eslint" ] && ESLINT_CMD="./node_modules/.bin/eslint"
            if $ESLINT_CMD . --ext .js,.ts 2>&1 | tee /tmp/node-lint.log; then
                echo "✅ **PASSED**" >> "$REPORT_FILE"
                echo -e "${GREEN}✓${RESET} Node.js linting passed"
            else
                echo "❌ **FAILED**" >> "$REPORT_FILE"
                echo -e "${RED}✗${RESET} Node.js linting failed"
                FAILED=1
            fi
        else
            echo "⚠️ **eslint not installed**" >> "$REPORT_FILE"
            echo -e "${YELLOW}!${RESET} eslint not installed (run: npm install -D eslint)"
        fi
    else
        echo "_No JS/TS files found_" >> "$REPORT_FILE"
        echo -e "${DIM}○ Node.js enabled but no .js/.ts files found${RESET}"
    fi
else
    echo "_Node.js not enabled_" >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# Rust linting
echo "## Rust Linting" >> "$REPORT_FILE"
if [ "$RUST_ENABLED" = "true" ]; then
    if find . -name "*.rs" -type f -not -path "./target/*" -not -path "./.git/*" -not -path "./.template/*" | grep -q .; then
        echo -e "${CYAN}Linting Rust code...${RESET}"
        if command -v cargo &> /dev/null; then
            if cargo clippy -- -D warnings 2>&1 | tee /tmp/rust-lint.log; then
                echo "✅ **PASSED**" >> "$REPORT_FILE"
                echo -e "${GREEN}✓${RESET} Rust linting passed"
            else
                echo "❌ **FAILED**" >> "$REPORT_FILE"
                echo -e "${RED}✗${RESET} Rust linting failed"
                FAILED=1
            fi
        else
            echo "⚠️ **cargo not installed**" >> "$REPORT_FILE"
            echo -e "${YELLOW}!${RESET} cargo not installed"
        fi
    else
        echo "_No Rust files found_" >> "$REPORT_FILE"
        echo -e "${DIM}○ Rust enabled but no .rs files found${RESET}"
    fi
else
    echo "_Rust not enabled_" >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# Summary
echo "---" >> "$REPORT_FILE"
echo ""
if [ $FAILED -eq 0 ]; then
    echo "## ✅ Result: PASSED" >> "$REPORT_FILE"
    echo -e "${GREEN}✅ All quality checks passed${RESET}"
else
    echo "## ❌ Result: FAILED" >> "$REPORT_FILE"
    echo -e "${RED}❌ Quality checks failed${RESET}"
    echo -e "${CYAN}💡 Run 'make quality-fix' to auto-fix issues${RESET}"
fi

echo ""
echo -e "${DIM}📊 Report: $REPORT_FILE${RESET}"

exit $FAILED
