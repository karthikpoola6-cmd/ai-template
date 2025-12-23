#!/bin/bash
# apply-config.sh - Process templates and generate project files

set -e

# Colors
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

# Use TEMPLATE_DIR from environment, or default to ".template" if not set
TEMPLATE_DIR="${TEMPLATE_DIR:-.template}"

# ============================================================================
# Cleanup Template Files
# ============================================================================
# Remove template-specific files that shouldn't be in the bootstrapped project

cleanup_template_files() {
    # Clean up any template files that ended up in the project root
    # (This can happen if .gitattributes export-ignore didn't work)

    local removed=0

    # Remove template documentation from root (if present)
    if [ -d "docs" ] && [ -f "docs/ADDING_LANGUAGES.md" ]; then
        rm -rf docs
        echo -e "  ${GREEN}✓${RESET} Removed: docs/ (template docs)"
        removed=$((removed + 1))
    fi

    # Remove examples directory from root (if present)
    if [ -d "examples" ] && [ -d "examples/python-cli" ]; then
        rm -rf examples
        echo -e "  ${GREEN}✓${RESET} Removed: examples/ (template examples)"
        removed=$((removed + 1))
    fi

    # Remove template config directory from root (if present)
    if [ -d "config" ] && [ -f "config/versions.yaml" ]; then
        rm -rf config
        echo -e "  ${GREEN}✓${RESET} Removed: config/ (template config)"
        removed=$((removed + 1))
    fi

    # Remove root scripts/bootstrap if present (template uses .template/scripts/)
    if [ -d "scripts/bootstrap" ] && [ -f "scripts/bootstrap/template_engine.py" ]; then
        rm -rf scripts/bootstrap
        echo -e "  ${GREEN}✓${RESET} Removed: scripts/bootstrap/"
        removed=$((removed + 1))
    fi

    # Remove empty scripts directory if nothing left
    if [ -d "scripts" ] && [ -z "$(ls -A scripts 2>/dev/null)" ]; then
        rmdir scripts 2>/dev/null || true
    fi

    if [ $removed -gt 0 ]; then
        echo -e "${CYAN}Cleaned up template files from project root${RESET}"
        echo ""
    fi
}

# Run cleanup first
cleanup_template_files

# ============================================================================
# Convert INSTALL_* to INCLUDE_* for template engine compatibility
# ============================================================================
# The bootstrap.sh uses INSTALL_* for tools, but template engine expects INCLUDE_*
export INCLUDE_CLAUDE_CODE="${INSTALL_CLAUDE_CODE:-false}"
export INCLUDE_GH_CLI="${INSTALL_GH_CLI:-false}"
export INCLUDE_GCLOUD="${INSTALL_GCLOUD:-false}"
export INCLUDE_PULUMI="${INSTALL_PULUMI:-false}"
export INCLUDE_INFISICAL="${INSTALL_INFISICAL:-false}"

# ============================================================================
# Template Processing Engine
# ============================================================================
# Uses Python-based template engine for:
# - Better error messages with line numbers
# - Support for {{#ELSE}} blocks
# - Nested conditionals
# - Easy extensibility
#
# See: .template/scripts/bootstrap/template_engine.py

# Locate the template engine script (relative to this script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_ENGINE="${SCRIPT_DIR}/template_engine.py"

# Fallback: try from repo root
if [ ! -f "$TEMPLATE_ENGINE" ]; then
    TEMPLATE_ENGINE=".template/scripts/bootstrap/template_engine.py"
fi

if [ ! -f "$TEMPLATE_ENGINE" ]; then
    echo -e "${RED}Error: Template engine not found${RESET}"
    echo -e "${RED}Expected at: .template/scripts/bootstrap/template_engine.py${RESET}"
    exit 1
fi

process_template() {
    local input_file="$1"
    local output_file="$2"

    # Create output directory if needed
    mkdir -p "$(dirname "$output_file")"

    # Process template using Python engine
    if ! python3 "$TEMPLATE_ENGINE" "$input_file" "$output_file"; then
        echo -e "  ${RED}✗${RESET} Failed: $output_file"
        return 1
    fi

    echo -e "  ${GREEN}✓${RESET} Generated: $output_file"
}

# ============================================================================
# File Overwrite Protection
# ============================================================================

check_existing_files() {
    local files_to_check=(
        ".github/workflows/ci.yml"
        ".github/workflows/quality.yml"
        ".pre-commit-config.yaml"
        "pyproject.toml"
        "go.mod"
        "package.json"
        "Cargo.toml"
    )

    local existing_files=()
    for file in "${files_to_check[@]}"; do
        [ -f "$file" ] && existing_files+=("$file")
    done

    if [ ${#existing_files[@]} -gt 0 ]; then
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "${YELLOW}  WARNING: Existing Files Will Be Overwritten${RESET}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo ""
        echo "The following files already exist and will be overwritten:"
        for file in "${existing_files[@]}"; do
            echo "  • $file"
        done
        echo ""
        read -p "Continue and overwrite these files? (y/n): " -n 1 -r OVERWRITE_CONFIRM
        echo ""
        if [[ ! $OVERWRITE_CONFIRM =~ ^[Yy]$ ]]; then
            echo -e "${RED}Cancelled.${RESET}"
            exit 1
        fi
        echo ""
    fi
}

# ============================================================================
# Main Processing
# ============================================================================

# Check for existing files before processing
check_existing_files

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${CYAN}  GENERATING PROJECT FILES${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

# DevContainer Files
echo -e "${CYAN}Generating devcontainer configuration...${RESET}"
mkdir -p .devcontainer

process_template "$TEMPLATE_DIR/.devcontainer/Dockerfile.dev.template" ".devcontainer/Dockerfile.dev"
process_template "$TEMPLATE_DIR/.devcontainer/docker-compose.yml.template" ".devcontainer/docker-compose.yml"
process_template "$TEMPLATE_DIR/.devcontainer/devcontainer.json.template" ".devcontainer/devcontainer.json"
process_template "$TEMPLATE_DIR/.devcontainer/post-create.sh.template" ".devcontainer/post-create.sh"
chmod +x .devcontainer/post-create.sh

if [ "$INCLUDE_POSTGRES" = "true" ]; then
    mkdir -p .devcontainer/init-scripts
    process_template "$TEMPLATE_DIR/.devcontainer/init-scripts/01-init.sql.template" ".devcontainer/init-scripts/01-init.sql"
fi

echo ""

# Makefile and Project Tooling
echo -e "${CYAN}Copying Makefile and project tooling...${RESET}"
cp "$TEMPLATE_DIR/Makefile" ./Makefile

# Append force commit targets if enabled
if [ "$INCLUDE_FORCE_COMMIT" = "true" ]; then
    cat >> ./Makefile << 'EOF'

# ============================================================================
# Work-in-Progress Commits (bypass pre-commit hooks)
# ============================================================================
# WARNING: Use only for WIP commits, never for production code!
# These commands bypass quality checks - use responsibly.

.PHONY: wip wip-push

wip: ## WIP commit - bypass pre-commit hooks (use for work-in-progress only)
	@echo "$(YELLOW)⚠️  Bypassing pre-commit hooks - WIP commit only!$(RESET)"
	@if [ -z "$$(git status --porcelain)" ]; then \
		echo "$(CYAN)Nothing to commit$(RESET)"; \
	else \
		git add -A && git commit --no-verify -m "WIP: $${MSG:-work in progress}"; \
		echo "$(GREEN)✅ WIP commit created$(RESET)"; \
		echo "$(DIM)Run 'make fix' before final commit$(RESET)"; \
	fi

wip-push: wip ## WIP commit and push (bypass all hooks)
	@git push --no-verify
	@echo "$(GREEN)✅ WIP pushed$(RESET)"
EOF
    echo -e "  ${GREEN}✓${RESET} Added: WIP commit targets (make wip)"
fi

echo -e "  ${GREEN}✓${RESET} Copied: Makefile"

# Copy .project/ directory (framework tooling)
mkdir -p .project
cp -r "$TEMPLATE_DIR/.project"/* ./.project/ 2>/dev/null || true
find .project -name "*.sh" -exec chmod +x {} \;
find .project -name "*.py" -exec chmod +x {} \;
echo -e "  ${GREEN}✓${RESET} Copied: .project/"

echo ""

# AI Workflows
if [ "$INCLUDE_AI_PROMPTS" = "true" ] || [ "$INCLUDE_AI_SESSIONS" = "true" ]; then
    echo -e "${CYAN}Setting up AI development workflows...${RESET}"
    cp -r "$TEMPLATE_DIR/.ai" ./ 2>/dev/null || true
    mkdir -p .ai/sessions
    echo -e "  ${GREEN}✓${RESET} Copied: .ai/"
    echo ""
fi

# ============================================================================
# GitHub Workflows
# ============================================================================

echo -e "${CYAN}Generating GitHub workflows...${RESET}"
mkdir -p .github/workflows

process_template "$TEMPLATE_DIR/.github/workflows/ci.yml.template" ".github/workflows/ci.yml"
process_template "$TEMPLATE_DIR/.github/workflows/quality.yml.template" ".github/workflows/quality.yml"

echo -e "  ${GREEN}✓${RESET} Generated: .github/workflows/"
echo ""

# ============================================================================
# Shared Configuration Files
# ============================================================================

echo -e "${CYAN}Copying shared configuration files...${RESET}"

# .editorconfig (no processing needed)
if [ -f "$TEMPLATE_DIR/configs/shared/.editorconfig" ]; then
    cp "$TEMPLATE_DIR/configs/shared/.editorconfig" ./.editorconfig
    echo -e "  ${GREEN}✓${RESET} Generated: .editorconfig"
fi

echo ""

# ============================================================================
# Pre-commit Configuration
# ============================================================================

if [ "$INCLUDE_PRECOMMIT" = "true" ]; then
    echo -e "${CYAN}Generating pre-commit configuration...${RESET}"
    process_template "$TEMPLATE_DIR/.pre-commit-config.yaml.template" "./.pre-commit-config.yaml"
    echo -e "  ${GREEN}✓${RESET} Generated: .pre-commit-config.yaml"
    echo ""
fi

# ============================================================================
# Language-Specific Configuration
# ============================================================================

if [ "$INCLUDE_PYTHON" = "true" ]; then
    echo -e "${CYAN}Generating Python configuration...${RESET}"
    process_template "$TEMPLATE_DIR/configs/python/pyproject.toml.template" "./pyproject.toml"
    process_template "$TEMPLATE_DIR/configs/python/ruff.toml.template" "./ruff.toml"
    process_template "$TEMPLATE_DIR/configs/python/pytest.ini.template" "./pytest.ini"
    echo -e "  ${GREEN}✓${RESET} Generated: Python configs"
    echo ""
fi

if [ "$INCLUDE_GO" = "true" ]; then
    echo -e "${CYAN}Generating Go configuration...${RESET}"
    process_template "$TEMPLATE_DIR/configs/go/go.mod.template" "./go.mod"
    process_template "$TEMPLATE_DIR/configs/go/.golangci.yml.template" "./.golangci.yml"
    echo -e "  ${GREEN}✓${RESET} Generated: Go configs"
    echo ""
fi

if [ "$INCLUDE_NODE" = "true" ]; then
    echo -e "${CYAN}Generating Node.js configuration...${RESET}"
    process_template "$TEMPLATE_DIR/configs/node/package.json.template" "./package.json"
    process_template "$TEMPLATE_DIR/configs/node/tsconfig.json.template" "./tsconfig.json"
    echo -e "  ${GREEN}✓${RESET} Generated: Node.js configs"
    echo ""
fi

if [ "$INCLUDE_RUST" = "true" ]; then
    echo -e "${CYAN}Generating Rust configuration...${RESET}"
    process_template "$TEMPLATE_DIR/configs/rust/Cargo.toml.template" "./Cargo.toml"
    echo -e "  ${GREEN}✓${RESET} Generated: Rust configs"
    echo ""
fi

# Project Configuration File (.project.yaml)
echo -e "${CYAN}Generating project configuration...${RESET}"

# Helper to convert env bool to yaml bool
yaml_bool() {
    [ "$1" = "true" ] && echo "true" || echo "false"
}

cat > .project.yaml << EOF
# Project Configuration
# Edit via: make config
# View via: make info

project:
  name: "${PROJECT_NAME:-my-project}"
  description: "${PROJECT_DESCRIPTION:-A new project}"

languages:
  python:
    enabled: $(yaml_bool "$INCLUDE_PYTHON")
    version: "${PYTHON_VERSION:-3.12}"
    quality:
      coverage: ${COVERAGE_THRESHOLD:-80}
      lint: true
      typecheck: true
      format: true

  go:
    enabled: $(yaml_bool "$INCLUDE_GO")
    version: "${GO_VERSION:-1.22.0}"
    quality:
      coverage: ${COVERAGE_THRESHOLD:-70}
      lint: true
      format: true

  node:
    enabled: $(yaml_bool "$INCLUDE_NODE")
    version: "${NODE_VERSION:-20}"
    quality:
      coverage: ${COVERAGE_THRESHOLD:-75}
      lint: true
      typecheck: true
      format: true

  rust:
    enabled: $(yaml_bool "$INCLUDE_RUST")
    version: "${RUST_VERSION:-stable}"
    quality:
      coverage: ${COVERAGE_THRESHOLD:-60}
      lint: true
      format: true

precommit: $(yaml_bool "$INCLUDE_PRECOMMIT")

infrastructure:
  postgres:
    enabled: $(yaml_bool "$INCLUDE_POSTGRES")
    version: "${POSTGRES_VERSION:-16}"
  redis:
    enabled: $(yaml_bool "$INCLUDE_REDIS")
    version: "${REDIS_VERSION:-7}"

tools:
  claude_code: $(yaml_bool "$INSTALL_CLAUDE_CODE")
  github_cli: $(yaml_bool "$INSTALL_GH_CLI")
  gcloud: $(yaml_bool "$INSTALL_GCLOUD")
  pulumi: $(yaml_bool "$INSTALL_PULUMI")
  infisical: $(yaml_bool "$INSTALL_INFISICAL")
EOF
echo -e "  ${GREEN}✓${RESET} Generated: .project.yaml"

# Also generate .quality.env for backwards compatibility with CI
cat > .quality.env << EOF
# Legacy quality configuration (for CI compatibility)
# Primary config is in .project.yaml - edit via: make config
COVERAGE_THRESHOLD=${COVERAGE_THRESHOLD:-80}
SKIP_QUALITY_CHECKS=false
SKIP_COVERAGE_CHECK=false
EOF
echo -e "  ${GREEN}✓${RESET} Generated: .quality.env (legacy)"

echo ""

# ============================================================================
# Sync Config to Language Files
# ============================================================================
# Auto-sync .project.yaml to language-specific config files (pyproject.toml, etc.)
# This ensures consistency between .project.yaml and generated configs

if [ -f ".project/config/project_config.py" ]; then
    echo -e "${CYAN}Syncing config to language files...${RESET}"
    if python3 .project/config/project_config.py sync 2>/dev/null; then
        echo -e "  ${GREEN}✓${RESET} Synced language configs"
    else
        echo -e "  ${YELLOW}⚠${RESET} Config sync skipped (no enabled languages or missing PyYAML)"
    fi
    echo ""
fi

# .gitignore
echo -e "${CYAN}Generating .gitignore...${RESET}"
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
vendor/
__pycache__/
*.pyc
.venv/
venv/
target/

# Build outputs
dist/
build/
*.egg-info/
bin/

# IDE
.idea/
.vscode/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Test & coverage
coverage/
htmlcov/
.coverage
coverage.out
coverage.xml
*.lcov

# Environment & secrets
.env
.env.local
*.pem
*.key

# Project config (uncomment to keep local-only)
# .project.yaml

# Logs
*.log
logs/

# Temporary
tmp/
.tmp/
EOF
echo -e "  ${GREEN}✓${RESET} Generated: .gitignore"

echo ""

# README
echo -e "${CYAN}Generating README.md...${RESET}"

# Try to detect GitHub org/repo from git remote, fall back to defaults
if [ -z "$GITHUB_ORG" ]; then
    # Try to extract from git remote origin URL
    REMOTE_URL=$(git config --get remote.origin.url 2>/dev/null || echo "")
    if [[ "$REMOTE_URL" =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
        GITHUB_ORG="${BASH_REMATCH[1]}"
        REPO_NAME="${BASH_REMATCH[2]}"
    else
        GITHUB_ORG="your-org"
        REPO_NAME="${PROJECT_NAME_KEBAB:-${PROJECT_NAME}}"
    fi
else
    REPO_NAME="${PROJECT_NAME_KEBAB:-${PROJECT_NAME}}"
fi

cat > README.md << EOF
# ${PROJECT_NAME}

[![CI](https://github.com/${GITHUB_ORG}/${REPO_NAME}/actions/workflows/ci.yml/badge.svg)](https://github.com/${GITHUB_ORG}/${REPO_NAME}/actions/workflows/ci.yml)
[![Quality](https://github.com/${GITHUB_ORG}/${REPO_NAME}/actions/workflows/quality.yml/badge.svg)](https://github.com/${GITHUB_ORG}/${REPO_NAME}/actions/workflows/quality.yml)

${PROJECT_DESCRIPTION}

## Quick Start

1. Open in Codespaces (or rebuild container)
2. Wait for post-create script to complete
3. Run \`make help\` to see available commands

## Tech Stack

EOF

[ "$INCLUDE_PYTHON" = "true" ] && echo "- **Python** ${PYTHON_VERSION}" >> README.md
[ "$INCLUDE_GO" = "true" ] && echo "- **Go** ${GO_VERSION}" >> README.md
[ "$INCLUDE_NODE" = "true" ] && echo "- **Node.js** ${NODE_VERSION}" >> README.md
[ "$INCLUDE_RUST" = "true" ] && echo "- **Rust** ${RUST_VERSION}" >> README.md
[ "$INCLUDE_POSTGRES" = "true" ] && echo "- **PostgreSQL** ${POSTGRES_VERSION}" >> README.md
[ "$INCLUDE_REDIS" = "true" ] && echo "- **Redis** ${REDIS_VERSION}" >> README.md

echo -e "  ${GREEN}✓${RESET} Generated: README.md"

echo ""

# ============================================================================
# Tool Installation
# ============================================================================

install_tool() {
    local name="$1"
    local check_cmd="$2"
    local install_cmd="$3"

    if command -v $check_cmd &> /dev/null; then
        echo -e "  ${GREEN}✓${RESET} $name already installed"
        return 0
    fi

    echo -e "  ${CYAN}→${RESET} Installing $name..."
    if eval "$install_cmd" &> /dev/null; then
        echo -e "  ${GREEN}✓${RESET} $name installed"
        return 0
    else
        echo -e "  ${YELLOW}!${RESET} Failed to install $name (install manually)"
        return 1
    fi
}

# Check if any tools need installation
if [ "$INSTALL_CLAUDE_CODE" = "true" ] || [ "$INSTALL_GH_CLI" = "true" ] || \
   [ "$INSTALL_GCLOUD" = "true" ] || [ "$INSTALL_PULUMI" = "true" ] || \
   [ "$INSTALL_INFISICAL" = "true" ] || [ "$INCLUDE_PRECOMMIT" = "true" ]; then

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${CYAN}  INSTALLING TOOLS${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
fi

# Pre-commit (Python tool)
if [ "$INCLUDE_PRECOMMIT" = "true" ]; then
    if command -v pre-commit &> /dev/null; then
        echo -e "  ${GREEN}✓${RESET} pre-commit already installed"
    else
        echo -e "  ${CYAN}→${RESET} Installing pre-commit..."
        if pip install pre-commit --quiet 2>/dev/null || pip3 install pre-commit --quiet 2>/dev/null; then
            echo -e "  ${GREEN}✓${RESET} pre-commit installed"
        else
            echo -e "  ${YELLOW}!${RESET} Failed to install pre-commit (run: pip install pre-commit)"
        fi
    fi

    # Install git hooks (ensure git repo is initialized first)
    if command -v pre-commit &> /dev/null; then
        if [ ! -d ".git" ]; then
            echo -e "  ${CYAN}→${RESET} Initializing git repository..."
            git init --quiet
        fi
        echo -e "  ${CYAN}→${RESET} Installing pre-commit git hooks..."
        if pre-commit install 2>/dev/null; then
            echo -e "  ${GREEN}✓${RESET} Pre-commit hooks installed"
        else
            echo -e "  ${YELLOW}!${RESET} Failed to install hooks (run: pre-commit install)"
        fi
    fi
fi

# Claude Code CLI
if [ "$INSTALL_CLAUDE_CODE" = "true" ]; then
    if command -v claude &> /dev/null; then
        echo -e "  ${GREEN}✓${RESET} Claude Code CLI already installed"
    else
        echo -e "  ${CYAN}→${RESET} Installing Claude Code CLI..."
        if command -v npm &> /dev/null; then
            if npm install -g @anthropic-ai/claude-code 2>/dev/null; then
                echo -e "  ${GREEN}✓${RESET} Claude Code CLI installed"
            else
                echo -e "  ${YELLOW}!${RESET} Failed to install Claude Code (run: npm install -g @anthropic-ai/claude-code)"
            fi
        else
            # npm not available - try to install Node.js first if on apt-based system
            if command -v apt-get &> /dev/null; then
                echo -e "  ${DIM}    npm not found, installing Node.js...${RESET}"
                if curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - \
                    && sudo apt-get install -y nodejs 2>/dev/null; then
                    # Now try installing Claude Code
                    if npm install -g @anthropic-ai/claude-code 2>/dev/null; then
                        echo -e "  ${GREEN}✓${RESET} Claude Code CLI installed"
                    else
                        echo -e "  ${YELLOW}!${RESET} Failed to install Claude Code (run: npm install -g @anthropic-ai/claude-code)"
                    fi
                else
                    echo -e "  ${YELLOW}!${RESET} npm not found - enable Node.js in bootstrap, or install manually:"
                    echo -e "      ${DIM}npm install -g @anthropic-ai/claude-code${RESET}"
                fi
            else
                echo -e "  ${YELLOW}!${RESET} npm not found - enable Node.js in bootstrap, or install manually:"
                echo -e "      ${DIM}npm install -g @anthropic-ai/claude-code${RESET}"
            fi
        fi
    fi
fi

# GitHub CLI
if [ "$INSTALL_GH_CLI" = "true" ]; then
    if command -v gh &> /dev/null; then
        echo -e "  ${GREEN}✓${RESET} GitHub CLI already installed"
    else
        echo -e "  ${CYAN}→${RESET} Installing GitHub CLI..."
        # Try different installation methods based on OS
        if command -v apt-get &> /dev/null; then
            # Debian/Ubuntu - requires sudo for system directories
            if (type -p wget >/dev/null || (sudo apt-get update && sudo apt-get install wget -y)) \
                && sudo mkdir -p -m 755 /etc/apt/keyrings \
                && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
                && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
                && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
                && sudo apt-get update && sudo apt-get install gh -y 2>/dev/null; then
                echo -e "  ${GREEN}✓${RESET} GitHub CLI installed"
            else
                echo -e "  ${YELLOW}!${RESET} Failed to install gh CLI (see: https://cli.github.com/)"
            fi
        elif command -v brew &> /dev/null; then
            # macOS with Homebrew
            if brew install gh 2>/dev/null; then
                echo -e "  ${GREEN}✓${RESET} GitHub CLI installed"
            else
                echo -e "  ${YELLOW}!${RESET} Failed to install gh CLI"
            fi
        else
            echo -e "  ${YELLOW}!${RESET} Cannot auto-install gh CLI (see: https://cli.github.com/)"
        fi
    fi
fi

# Google Cloud SDK
if [ "$INSTALL_GCLOUD" = "true" ]; then
    if command -v gcloud &> /dev/null; then
        echo -e "  ${GREEN}✓${RESET} Google Cloud SDK already installed"
    else
        echo -e "  ${CYAN}→${RESET} Installing Google Cloud SDK..."
        if command -v apt-get &> /dev/null; then
            # Debian/Ubuntu - requires sudo for system directories
            if sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates gnupg curl \
                && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
                && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list \
                && sudo apt-get update && sudo apt-get install -y google-cloud-cli 2>/dev/null; then
                echo -e "  ${GREEN}✓${RESET} Google Cloud SDK installed"
            else
                echo -e "  ${YELLOW}!${RESET} Failed to install gcloud (see: https://cloud.google.com/sdk/docs/install)"
            fi
        elif command -v brew &> /dev/null; then
            if brew install google-cloud-sdk 2>/dev/null; then
                echo -e "  ${GREEN}✓${RESET} Google Cloud SDK installed"
            else
                echo -e "  ${YELLOW}!${RESET} Failed to install gcloud"
            fi
        else
            echo -e "  ${YELLOW}!${RESET} Cannot auto-install gcloud (see: https://cloud.google.com/sdk/docs/install)"
        fi
    fi
fi

# Pulumi
if [ "$INSTALL_PULUMI" = "true" ]; then
    if command -v pulumi &> /dev/null; then
        echo -e "  ${GREEN}✓${RESET} Pulumi already installed"
    else
        echo -e "  ${CYAN}→${RESET} Installing Pulumi..."
        if curl -fsSL https://get.pulumi.com | sh 2>/dev/null; then
            echo -e "  ${GREEN}✓${RESET} Pulumi installed"
            echo -e "    ${DIM}Add to PATH: export PATH=\$PATH:\$HOME/.pulumi/bin${RESET}"
        else
            echo -e "  ${YELLOW}!${RESET} Failed to install Pulumi (see: https://www.pulumi.com/docs/install/)"
        fi
    fi
fi

# Infisical
if [ "$INSTALL_INFISICAL" = "true" ]; then
    if command -v infisical &> /dev/null; then
        echo -e "  ${GREEN}✓${RESET} Infisical already installed"
    else
        echo -e "  ${CYAN}→${RESET} Installing Infisical..."
        if command -v apt-get &> /dev/null; then
            # Debian/Ubuntu - requires sudo for system directories
            # Use official Infisical repository (updated April 2025)
            if curl -1sLf 'https://artifacts-cli.infisical.com/setup.deb.sh' | sudo -E bash \
                && sudo apt-get update && sudo apt-get install -y infisical 2>/dev/null; then
                echo -e "  ${GREEN}✓${RESET} Infisical installed"
            else
                echo -e "  ${YELLOW}!${RESET} Failed to install Infisical (see: https://infisical.com/docs/cli/overview)"
            fi
        elif command -v brew &> /dev/null; then
            if brew install infisical/get-cli/infisical 2>/dev/null; then
                echo -e "  ${GREEN}✓${RESET} Infisical installed"
            else
                echo -e "  ${YELLOW}!${RESET} Failed to install Infisical"
            fi
        else
            echo -e "  ${YELLOW}!${RESET} Cannot auto-install Infisical (see: https://infisical.com/docs/cli/overview)"
        fi
    fi
fi

# ============================================================================
# Quality Tools Installation (based on enabled languages)
# ============================================================================

# Check if any languages are enabled that need quality tools
if [ "$INCLUDE_PYTHON" = "true" ] || [ "$INCLUDE_GO" = "true" ] || \
   [ "$INCLUDE_NODE" = "true" ] || [ "$INCLUDE_RUST" = "true" ]; then

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${CYAN}  INSTALLING QUALITY TOOLS${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
fi

# Python quality tools
if [ "$INCLUDE_PYTHON" = "true" ]; then
    echo -e "${CYAN}Python quality tools:${RESET}"

    # Check if pip is available
    if command -v pip &> /dev/null || command -v pip3 &> /dev/null; then
        PIP_CMD="pip"
        command -v pip &> /dev/null || PIP_CMD="pip3"

        # Install quality tools (versions synced with .template/config/versions.yaml)
        PYTHON_TOOLS="ruff>=0.8.0 mypy>=1.8.0 pytest>=8.0.0 pytest-cov pytest-asyncio"
        echo -e "  ${CYAN}→${RESET} Installing: ruff mypy pytest pytest-cov pytest-asyncio"
        if $PIP_CMD install --quiet $PYTHON_TOOLS 2>/dev/null; then
            echo -e "  ${GREEN}✓${RESET} ruff (linter + formatter)"
            echo -e "  ${GREEN}✓${RESET} mypy (type checker)"
            echo -e "  ${GREEN}✓${RESET} pytest + pytest-cov (testing)"
        else
            echo -e "  ${YELLOW}!${RESET} Some tools failed to install (run: pip install $PYTHON_TOOLS)"
        fi
    else
        echo -e "  ${YELLOW}!${RESET} pip not found - cannot install Python quality tools"
    fi
    echo ""
fi

# Go quality tools
if [ "$INCLUDE_GO" = "true" ]; then
    echo -e "${CYAN}Go quality tools:${RESET}"

    if command -v go &> /dev/null; then
        # golangci-lint
        echo -e "  ${CYAN}→${RESET} Installing golangci-lint..."
        if go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest 2>/dev/null; then
            echo -e "  ${GREEN}✓${RESET} golangci-lint (linter)"
        else
            echo -e "  ${YELLOW}!${RESET} Failed to install golangci-lint"
        fi

        # goimports
        echo -e "  ${CYAN}→${RESET} Installing goimports..."
        if go install golang.org/x/tools/cmd/goimports@latest 2>/dev/null; then
            echo -e "  ${GREEN}✓${RESET} goimports (formatter)"
        else
            echo -e "  ${YELLOW}!${RESET} Failed to install goimports"
        fi

        # delve debugger
        echo -e "  ${CYAN}→${RESET} Installing delve..."
        if go install github.com/go-delve/delve/cmd/dlv@latest 2>/dev/null; then
            echo -e "  ${GREEN}✓${RESET} delve (debugger)"
        else
            echo -e "  ${YELLOW}!${RESET} Failed to install delve"
        fi
    else
        echo -e "  ${YELLOW}!${RESET} Go not found - cannot install Go quality tools"
    fi
    echo ""
fi

# Node.js quality tools
if [ "$INCLUDE_NODE" = "true" ]; then
    echo -e "${CYAN}Node.js quality tools:${RESET}"

    if command -v npm &> /dev/null; then
        # Install dev dependencies if package.json exists
        if [ -f "package.json" ]; then
            echo -e "  ${CYAN}→${RESET} Installing project dependencies..."
            if npm install 2>/dev/null; then
                echo -e "  ${GREEN}✓${RESET} npm dependencies installed"
            else
                echo -e "  ${YELLOW}!${RESET} Failed to install npm dependencies"
            fi
        else
            # Install common quality tools globally
            echo -e "  ${CYAN}→${RESET} Installing eslint and prettier..."
            if npm install -g eslint prettier typescript 2>/dev/null; then
                echo -e "  ${GREEN}✓${RESET} eslint (linter)"
                echo -e "  ${GREEN}✓${RESET} prettier (formatter)"
                echo -e "  ${GREEN}✓${RESET} typescript (type checker)"
            else
                echo -e "  ${YELLOW}!${RESET} Failed to install Node.js tools (run: npm install -g eslint prettier typescript)"
            fi
        fi
    else
        echo -e "  ${YELLOW}!${RESET} npm not found - cannot install Node.js quality tools"
    fi
    echo ""
fi

# Rust quality tools
if [ "$INCLUDE_RUST" = "true" ]; then
    echo -e "${CYAN}Rust quality tools:${RESET}"

    if command -v rustup &> /dev/null; then
        # Install rustfmt and clippy via rustup
        echo -e "  ${CYAN}→${RESET} Installing rustfmt and clippy..."
        if rustup component add rustfmt clippy 2>/dev/null; then
            echo -e "  ${GREEN}✓${RESET} rustfmt (formatter)"
            echo -e "  ${GREEN}✓${RESET} clippy (linter)"
        else
            echo -e "  ${YELLOW}!${RESET} Failed to install rustfmt/clippy"
        fi

        # Install cargo-watch
        echo -e "  ${CYAN}→${RESET} Installing cargo-watch..."
        if cargo install cargo-watch 2>/dev/null; then
            echo -e "  ${GREEN}✓${RESET} cargo-watch (file watcher)"
        else
            echo -e "  ${YELLOW}!${RESET} Failed to install cargo-watch"
        fi
    else
        echo -e "  ${YELLOW}!${RESET} rustup not found - cannot install Rust quality tools"
    fi
    echo ""
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${GREEN}  CONFIGURATION COMPLETE${RESET}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "${DIM}Kept: bootstrap.sh, .template/ (for re-running bootstrap later)${RESET}"
echo ""
