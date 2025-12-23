#!/bin/bash
#
# Bootstrap Script for Codespaces AI Template
# ============================================
#
# This script initializes a new project from the template.
#
# Usage:
#   ./bootstrap.sh                    # Interactive mode
#   ./bootstrap.sh --quick            # Quick start with Python only
#   ./bootstrap.sh --help             # Show help
#
# Requirements:
#   - Python 3.10+
#   - PyYAML (pip install pyyaml)
#

set -e

# Colors
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

TEMPLATE_DIR=".template"

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${CYAN}  $1${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
}

check_requirements() {
    local missing=()

    # Check Python 3
    if ! command -v python3 &> /dev/null; then
        missing+=("python3")
    else
        # Check Python version >= 3.10
        local version=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
        local major=$(echo $version | cut -d. -f1)
        local minor=$(echo $version | cut -d. -f2)
        if [ "$major" -lt 3 ] || ([ "$major" -eq 3 ] && [ "$minor" -lt 10 ]); then
            echo -e "${RED}Error: Python 3.10+ required (found $version)${RESET}"
            exit 1
        fi
        echo -e "  ${GREEN}✓${RESET} Python $version"
    fi

    # Check PyYAML
    if python3 -c "import yaml" 2>/dev/null; then
        echo -e "  ${GREEN}✓${RESET} PyYAML installed"
    else
        echo -e "  ${YELLOW}!${RESET} PyYAML not installed"
        echo -e "    ${DIM}Installing PyYAML...${RESET}"
        pip install pyyaml --quiet
        echo -e "  ${GREEN}✓${RESET} PyYAML installed"
    fi

    # Check make
    if command -v make &> /dev/null; then
        echo -e "  ${GREEN}✓${RESET} make available"
    else
        echo -e "  ${YELLOW}!${RESET} make not found (optional, but recommended)"
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}Error: Missing requirements: ${missing[*]}${RESET}"
        exit 1
    fi
}

show_help() {
    echo "Usage: ./bootstrap.sh [OPTIONS]"
    echo ""
    echo "Initialize a new project from the Codespaces AI Template."
    echo ""
    echo "Modes:"
    echo "  (no options)      Interactive mode - prompts for all options"
    echo "  --quick           Quick start with Python + Claude Code + GitHub CLI"
    echo ""
    echo "Language options:"
    echo "  --python          Enable Python"
    echo "  --go              Enable Go"
    echo "  --node            Enable Node.js"
    echo "  --rust            Enable Rust"
    echo "  --all             Enable all languages"
    echo ""
    echo "Project options:"
    echo "  --name NAME       Set project name (default: directory name)"
    echo "  --help            Show this help message"
    echo ""
    echo "Interactive mode prompts for:"
    echo "  - Languages (Python, Go, Node.js, Rust) with version selection"
    echo "  - Infrastructure (PostgreSQL, Redis)"
    echo "  - Developer tools (Claude Code, GitHub CLI, pre-commit)"
    echo "  - Cloud tools (gcloud, Pulumi, Infisical)"
    echo "  - AI workflows and coverage thresholds"
    echo ""
    echo "Examples:"
    echo "  ./bootstrap.sh                      # Full interactive setup"
    echo "  ./bootstrap.sh --quick              # Python + tools, quick start"
    echo "  ./bootstrap.sh --python --go        # Python and Go (non-interactive)"
    echo "  ./bootstrap.sh --all --name myapp   # All languages, custom name"
    echo ""
}

# ============================================================================
# Interactive Mode
# ============================================================================

interactive_setup() {
    print_header "PROJECT SETUP"

    # Project name
    local default_name=$(basename "$(pwd)")
    read -p "Project name [$default_name]: " PROJECT_NAME
    PROJECT_NAME="${PROJECT_NAME:-$default_name}"

    read -p "Project description [A new project]: " PROJECT_DESCRIPTION
    PROJECT_DESCRIPTION="${PROJECT_DESCRIPTION:-A new project}"

    echo ""
    echo -e "${BOLD}Select languages to enable:${RESET}"
    echo ""

    # Python
    read -p "  Enable Python? [Y/n]: " -n 1 -r enable_python
    echo ""
    if [[ ! $enable_python =~ ^[Nn]$ ]]; then
        INCLUDE_PYTHON=true
        read -p "    Python version [3.12]: " PYTHON_VERSION
        PYTHON_VERSION="${PYTHON_VERSION:-3.12}"
    else
        INCLUDE_PYTHON=false
    fi

    # Go
    read -p "  Enable Go? [y/N]: " -n 1 -r enable_go
    echo ""
    if [[ $enable_go =~ ^[Yy]$ ]]; then
        INCLUDE_GO=true
        read -p "    Go version [1.22.0]: " GO_VERSION
        GO_VERSION="${GO_VERSION:-1.22.0}"
    else
        INCLUDE_GO=false
    fi

    # Node.js
    read -p "  Enable Node.js? [y/N]: " -n 1 -r enable_node
    echo ""
    if [[ $enable_node =~ ^[Yy]$ ]]; then
        INCLUDE_NODE=true
        read -p "    Node.js version [20]: " NODE_VERSION
        NODE_VERSION="${NODE_VERSION:-20}"
    else
        INCLUDE_NODE=false
    fi

    # Rust
    read -p "  Enable Rust? [y/N]: " -n 1 -r enable_rust
    echo ""
    if [[ $enable_rust =~ ^[Yy]$ ]]; then
        INCLUDE_RUST=true
        read -p "    Rust version [stable]: " RUST_VERSION
        RUST_VERSION="${RUST_VERSION:-stable}"
    else
        INCLUDE_RUST=false
    fi

    echo ""
    echo -e "${BOLD}Infrastructure:${RESET}"
    echo ""

    # PostgreSQL
    read -p "  Enable PostgreSQL? [y/N]: " -n 1 -r enable_pg
    echo ""
    if [[ $enable_pg =~ ^[Yy]$ ]]; then
        INCLUDE_POSTGRES=true
        read -p "    PostgreSQL version [16]: " POSTGRES_VERSION
        POSTGRES_VERSION="${POSTGRES_VERSION:-16}"
    else
        INCLUDE_POSTGRES=false
    fi

    # Redis
    read -p "  Enable Redis? [y/N]: " -n 1 -r enable_redis
    echo ""
    if [[ $enable_redis =~ ^[Yy]$ ]]; then
        INCLUDE_REDIS=true
        read -p "    Redis version [7]: " REDIS_VERSION
        REDIS_VERSION="${REDIS_VERSION:-7}"
    else
        INCLUDE_REDIS=false
    fi

    echo ""
    echo -e "${BOLD}Developer Tools:${RESET}"
    echo ""

    # Claude Code
    read -p "  Install Claude Code CLI? [Y/n]: " -n 1 -r enable_claude
    echo ""
    if [[ ! $enable_claude =~ ^[Nn]$ ]]; then
        INSTALL_CLAUDE_CODE=true
    else
        INSTALL_CLAUDE_CODE=false
    fi

    # GitHub CLI
    read -p "  Install GitHub CLI (gh)? [Y/n]: " -n 1 -r enable_gh
    echo ""
    if [[ ! $enable_gh =~ ^[Nn]$ ]]; then
        INSTALL_GH_CLI=true
    else
        INSTALL_GH_CLI=false
    fi

    # Pre-commit
    read -p "  Enable pre-commit hooks? [Y/n]: " -n 1 -r enable_precommit
    echo ""
    if [[ ! $enable_precommit =~ ^[Nn]$ ]]; then
        INCLUDE_PRECOMMIT=true
    else
        INCLUDE_PRECOMMIT=false
    fi

    echo ""
    echo -e "${BOLD}Cloud & Infrastructure Tools (optional):${RESET}"
    echo ""

    # Google Cloud SDK
    read -p "  Install Google Cloud SDK (gcloud)? [y/N]: " -n 1 -r enable_gcloud
    echo ""
    if [[ $enable_gcloud =~ ^[Yy]$ ]]; then
        INSTALL_GCLOUD=true
    else
        INSTALL_GCLOUD=false
    fi

    # Pulumi
    read -p "  Install Pulumi (IaC)? [y/N]: " -n 1 -r enable_pulumi
    echo ""
    if [[ $enable_pulumi =~ ^[Yy]$ ]]; then
        INSTALL_PULUMI=true
    else
        INSTALL_PULUMI=false
    fi

    # Infisical
    read -p "  Install Infisical (secrets management)? [y/N]: " -n 1 -r enable_infisical
    echo ""
    if [[ $enable_infisical =~ ^[Yy]$ ]]; then
        INSTALL_INFISICAL=true
    else
        INSTALL_INFISICAL=false
    fi

    echo ""
    echo -e "${BOLD}Additional options:${RESET}"
    echo ""

    # AI workflows
    read -p "  Enable AI development workflows? [Y/n]: " -n 1 -r enable_ai
    echo ""
    if [[ ! $enable_ai =~ ^[Nn]$ ]]; then
        INCLUDE_AI_PROMPTS=true
        INCLUDE_AI_SESSIONS=true
    else
        INCLUDE_AI_PROMPTS=false
        INCLUDE_AI_SESSIONS=false
    fi

    # Coverage threshold
    read -p "  Coverage threshold % [80]: " COVERAGE_THRESHOLD
    COVERAGE_THRESHOLD="${COVERAGE_THRESHOLD:-80}"

    # Force commit (bypass pre-commit hooks)
    echo ""
    echo -e "  ${DIM}Force commit allows bypassing pre-commit hooks for WIP commits.${RESET}"
    echo -e "  ${DIM}Use with caution - only for work-in-progress, never for production.${RESET}"
    read -p "  Enable 'make wip' for force commit? [y/N]: " -n 1 -r enable_force
    echo ""
    if [[ $enable_force =~ ^[Yy]$ ]]; then
        INCLUDE_FORCE_COMMIT=true
    else
        INCLUDE_FORCE_COMMIT=false
    fi

    # Confirm
    echo ""
    print_header "CONFIGURATION SUMMARY"
    echo -e "  Project:      ${BOLD}$PROJECT_NAME${RESET}"
    echo -e "  Description:  $PROJECT_DESCRIPTION"
    echo ""
    echo -e "  ${BOLD}Languages:${RESET}"
    [ "$INCLUDE_PYTHON" = "true" ] && echo -e "    ${GREEN}✓${RESET} Python $PYTHON_VERSION"
    [ "$INCLUDE_GO" = "true" ] && echo -e "    ${GREEN}✓${RESET} Go $GO_VERSION"
    [ "$INCLUDE_NODE" = "true" ] && echo -e "    ${GREEN}✓${RESET} Node.js $NODE_VERSION"
    [ "$INCLUDE_RUST" = "true" ] && echo -e "    ${GREEN}✓${RESET} Rust $RUST_VERSION"
    [ "$INCLUDE_PYTHON" = "false" ] && [ "$INCLUDE_GO" = "false" ] && [ "$INCLUDE_NODE" = "false" ] && [ "$INCLUDE_RUST" = "false" ] && echo -e "    ${DIM}None${RESET}"
    echo ""
    echo -e "  ${BOLD}Infrastructure:${RESET}"
    [ "$INCLUDE_POSTGRES" = "true" ] && echo -e "    ${GREEN}✓${RESET} PostgreSQL $POSTGRES_VERSION"
    [ "$INCLUDE_REDIS" = "true" ] && echo -e "    ${GREEN}✓${RESET} Redis $REDIS_VERSION"
    [ "$INCLUDE_POSTGRES" = "false" ] && [ "$INCLUDE_REDIS" = "false" ] && echo -e "    ${DIM}None${RESET}"
    echo ""
    echo -e "  ${BOLD}Developer Tools:${RESET}"
    [ "$INSTALL_CLAUDE_CODE" = "true" ] && echo -e "    ${GREEN}✓${RESET} Claude Code CLI"
    [ "$INSTALL_GH_CLI" = "true" ] && echo -e "    ${GREEN}✓${RESET} GitHub CLI"
    [ "$INCLUDE_PRECOMMIT" = "true" ] && echo -e "    ${GREEN}✓${RESET} Pre-commit hooks"
    echo ""
    echo -e "  ${BOLD}Cloud Tools:${RESET}"
    [ "$INSTALL_GCLOUD" = "true" ] && echo -e "    ${GREEN}✓${RESET} Google Cloud SDK"
    [ "$INSTALL_PULUMI" = "true" ] && echo -e "    ${GREEN}✓${RESET} Pulumi"
    [ "$INSTALL_INFISICAL" = "true" ] && echo -e "    ${GREEN}✓${RESET} Infisical"
    [ "$INSTALL_GCLOUD" = "false" ] && [ "$INSTALL_PULUMI" = "false" ] && [ "$INSTALL_INFISICAL" = "false" ] && echo -e "    ${DIM}None${RESET}"
    echo ""
    echo -e "  ${BOLD}Options:${RESET}"
    [ "$INCLUDE_AI_PROMPTS" = "true" ] && echo -e "    ${GREEN}✓${RESET} AI workflows"
    [ "$INCLUDE_FORCE_COMMIT" = "true" ] && echo -e "    ${GREEN}✓${RESET} Force commit (make wip)"
    echo -e "    Coverage: ${COVERAGE_THRESHOLD}%"
    echo ""

    read -p "Proceed with this configuration? [Y/n]: " -n 1 -r confirm
    echo ""
    if [[ $confirm =~ ^[Nn]$ ]]; then
        echo -e "${YELLOW}Cancelled.${RESET}"
        exit 0
    fi
}

# ============================================================================
# Quick Mode (Python only)
# ============================================================================

quick_setup() {
    PROJECT_NAME="${PROJECT_NAME:-$(basename "$(pwd)")}"
    PROJECT_DESCRIPTION="${PROJECT_DESCRIPTION:-A new project}"
    INCLUDE_PYTHON=true
    PYTHON_VERSION="${PYTHON_VERSION:-3.12}"
    INCLUDE_GO=false
    INCLUDE_NODE=false
    INCLUDE_RUST=false
    INCLUDE_POSTGRES=false
    INCLUDE_REDIS=false
    INCLUDE_PRECOMMIT=true
    INCLUDE_AI_PROMPTS=true
    INCLUDE_AI_SESSIONS=true
    INCLUDE_FORCE_COMMIT=false
    COVERAGE_THRESHOLD="${COVERAGE_THRESHOLD:-80}"
    # Tool installation defaults for quick mode
    INSTALL_CLAUDE_CODE=true
    INSTALL_GH_CLI=true
    INSTALL_GCLOUD=false
    INSTALL_PULUMI=false
    INSTALL_INFISICAL=false

    echo -e "${CYAN}Quick setup: Python ${PYTHON_VERSION} project${RESET}"
    echo -e "${DIM}  With: Claude Code, GitHub CLI, pre-commit${RESET}"
}

# ============================================================================
# Main
# ============================================================================

main() {
    print_header "CODESPACES AI TEMPLATE"
    echo -e "  ${DIM}Bootstrap a new project with best practices${RESET}"
    echo ""

    # Check requirements
    echo -e "${CYAN}Checking requirements...${RESET}"
    check_requirements
    echo ""

    # Parse arguments
    local mode="interactive"

    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --quick|-q)
                mode="quick"
                shift
                ;;
            --name)
                PROJECT_NAME="$2"
                shift 2
                ;;
            --python)
                INCLUDE_PYTHON=true
                shift
                ;;
            --go)
                INCLUDE_GO=true
                shift
                ;;
            --node)
                INCLUDE_NODE=true
                shift
                ;;
            --rust)
                INCLUDE_RUST=true
                shift
                ;;
            --all)
                INCLUDE_PYTHON=true
                INCLUDE_GO=true
                INCLUDE_NODE=true
                INCLUDE_RUST=true
                shift
                ;;
            *)
                echo -e "${RED}Unknown option: $1${RESET}"
                show_help
                exit 1
                ;;
        esac
    done

    # Run setup
    if [ "$mode" = "quick" ]; then
        quick_setup
    else
        # If any language flags were passed, use non-interactive
        if [ "$INCLUDE_PYTHON" = "true" ] || [ "$INCLUDE_GO" = "true" ] || \
           [ "$INCLUDE_NODE" = "true" ] || [ "$INCLUDE_RUST" = "true" ]; then
            # Set defaults for non-interactive
            PROJECT_NAME="${PROJECT_NAME:-$(basename "$(pwd)")}"
            PROJECT_DESCRIPTION="${PROJECT_DESCRIPTION:-A new project}"
            INCLUDE_PYTHON="${INCLUDE_PYTHON:-false}"
            INCLUDE_GO="${INCLUDE_GO:-false}"
            INCLUDE_NODE="${INCLUDE_NODE:-false}"
            INCLUDE_RUST="${INCLUDE_RUST:-false}"
            PYTHON_VERSION="${PYTHON_VERSION:-3.12}"
            GO_VERSION="${GO_VERSION:-1.22.0}"
            NODE_VERSION="${NODE_VERSION:-20}"
            RUST_VERSION="${RUST_VERSION:-stable}"
            INCLUDE_POSTGRES="${INCLUDE_POSTGRES:-false}"
            INCLUDE_REDIS="${INCLUDE_REDIS:-false}"
            INCLUDE_PRECOMMIT="${INCLUDE_PRECOMMIT:-true}"
            INCLUDE_AI_PROMPTS="${INCLUDE_AI_PROMPTS:-true}"
            INCLUDE_AI_SESSIONS="${INCLUDE_AI_SESSIONS:-true}"
            INCLUDE_FORCE_COMMIT="${INCLUDE_FORCE_COMMIT:-false}"
            COVERAGE_THRESHOLD="${COVERAGE_THRESHOLD:-80}"
            # Tool installation defaults for non-interactive
            INSTALL_CLAUDE_CODE="${INSTALL_CLAUDE_CODE:-true}"
            INSTALL_GH_CLI="${INSTALL_GH_CLI:-true}"
            INSTALL_GCLOUD="${INSTALL_GCLOUD:-false}"
            INSTALL_PULUMI="${INSTALL_PULUMI:-false}"
            INSTALL_INFISICAL="${INSTALL_INFISICAL:-false}"
        else
            interactive_setup
        fi
    fi

    # Export all variables for apply-config.sh
    export PROJECT_NAME PROJECT_DESCRIPTION
    export INCLUDE_PYTHON PYTHON_VERSION
    export INCLUDE_GO GO_VERSION
    export INCLUDE_NODE NODE_VERSION
    export INCLUDE_RUST RUST_VERSION
    export INCLUDE_POSTGRES POSTGRES_VERSION
    export INCLUDE_REDIS REDIS_VERSION
    export INCLUDE_PRECOMMIT
    export INCLUDE_AI_PROMPTS INCLUDE_AI_SESSIONS
    export INCLUDE_FORCE_COMMIT
    export COVERAGE_THRESHOLD
    export TEMPLATE_DIR
    # Export tool installation flags
    export INSTALL_CLAUDE_CODE INSTALL_GH_CLI
    export INSTALL_GCLOUD INSTALL_PULUMI INSTALL_INFISICAL

    # Run the actual bootstrap
    bash "$TEMPLATE_DIR/scripts/bootstrap/apply-config.sh"

    # Success message
    print_header "BOOTSTRAP COMPLETE"
    echo -e "  Your project is ready!"
    echo ""
    echo -e "  ${BOLD}Next steps:${RESET}"
    echo -e "    1. Run ${CYAN}make doctor${RESET} to verify your setup"
    echo -e "    2. Run ${CYAN}make info${RESET} to see your configuration"
    echo -e "    3. Run ${CYAN}make help${RESET} to see available commands"
    echo -e "    4. Start coding!"
    echo ""
    echo -e "  ${DIM}Configuration: .project.yaml${RESET}"
    echo -e "  ${DIM}Edit config:   make config${RESET}"
    echo ""
}

main "$@"
