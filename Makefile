.PHONY: help ai-start ai-step ai-checkpoint ai-history
.PHONY: session-start session-end session-commit session-push session-pr

# Colors for output
CYAN := \033[36m
GREEN := \033[32m
YELLOW := \033[33m
RESET := \033[0m

help: ## Show this help message
	@echo "$(CYAN)AI-Assisted Development System$(RESET)"
	@echo ""
	@echo "$(CYAN)Available commands:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ============================================================================
# AI-Assisted Development (Low-level)
# ============================================================================

ai-start: ## Start AI-assisted development session (shows checkpoint + prompt)
	@./.project/scripts/session/start.sh

ai-step: ## Show step-by-step development prompt
	@echo "$(CYAN)📋 Step-by-Step Development Guide:$(RESET)"
	@echo ""
	@cat .ai/prompts/step-by-step.md

ai-checkpoint: ## Create session checkpoint
	@echo "$(CYAN)💾 Creating Session Checkpoint$(RESET)"
	@echo "=============================="
	@echo ""
	@DEVELOPER=$$(git config user.name | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g'); \
	DATE=$$(date +%Y-%m-%d); \
	SESSIONS_DIR=".ai/sessions/$$DEVELOPER/$$DATE"; \
	mkdir -p $$SESSIONS_DIR; \
	SESSION_NUM=1; \
	while [ -f "$$SESSIONS_DIR/session-$$SESSION_NUM.md" ]; do \
		SESSION_NUM=$$((SESSION_NUM + 1)); \
	done; \
	CHECKPOINT_FILE="$$SESSIONS_DIR/session-$$SESSION_NUM.md"; \
	echo "$(CYAN)Creating:$(RESET) $$CHECKPOINT_FILE"; \
	echo ""; \
	echo "$(CYAN)📋 Session End Prompt:$(RESET)"; \
	echo ""; \
	cat .ai/prompts/session-end.md; \
	echo ""; \
	echo "════════════════════════════════════════════════════════════════"; \
	echo ""; \
	echo "$(CYAN)Checkpoint will be created at:$(RESET) $$CHECKPOINT_FILE"; \
	echo "$(CYAN)Template location:$(RESET) .ai/templates/session-checkpoint-template.md"

ai-history: ## Show recent AI session history
	@echo "$(CYAN)📚 Recent AI Sessions$(RESET)"
	@echo "====================="
	@echo ""
	@DEVELOPER=$$(git config user.name | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g'); \
	SESSIONS_DIR=".ai/sessions/$$DEVELOPER"; \
	if [ -d "$$SESSIONS_DIR" ]; then \
		echo "$(CYAN)Sessions for $$DEVELOPER:$(RESET)"; \
		echo ""; \
		for file in $$(find $$SESSIONS_DIR -name "session-*.md" -type f 2>/dev/null | sort -r | head -5); do \
			DATE_DIR=$$(basename $$(dirname $$file)); \
			SESSION=$$(basename $$file); \
			echo "$(CYAN)📄 $$DATE_DIR/$$SESSION$(RESET)"; \
			echo "   Path: $$file"; \
			GOAL=$$(grep -m 1 "^## Session Goal" $$file -A 1 | tail -1); \
			if [ -n "$$GOAL" ]; then \
				echo "   Goal: $$GOAL"; \
			fi; \
			echo ""; \
		done; \
		TOTAL=$$(find $$SESSIONS_DIR -name "session-*.md" -type f 2>/dev/null | wc -l); \
		if [ $$TOTAL -gt 5 ]; then \
			echo "$(CYAN)... and $$(( $$TOTAL - 5 )) more$(RESET)"; \
		fi; \
	else \
		echo "$(CYAN)ℹ️  No sessions found for $$DEVELOPER$(RESET)"; \
	fi; \
	echo ""; \
	echo "$(CYAN)All developers:$(RESET)"; \
	for dev_dir in .ai/sessions/*/; do \
		if [ -d "$$dev_dir" ]; then \
			DEV_NAME=$$(basename $$dev_dir); \
			COUNT=$$(find $$dev_dir -name "session-*.md" -type f 2>/dev/null | wc -l); \
			echo "  • $$DEV_NAME: $$COUNT session(s)"; \
		fi; \
	done

# ============================================================================
# Session Management (High-level, User-friendly)
# ============================================================================

session-start: ai-start ## Start a new development session (recommended)

session-end: ## End current session (shows checklist and guides checkpoint creation)
	@./.project/scripts/session/end.sh

session-commit: ## Commit session work (add SKIP_VERIFY=1 to skip hooks)
	@./.project/scripts/session/commit.sh

session-push: ## Push session work to remote
	@git push

session-pr: ## Create pull request with auto-generated content (BASE=main to override base branch)
	@./.project/scripts/session/create-pr.sh $(BASE)
