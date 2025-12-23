# AI-Assisted Development System

A lightweight template with make-based AI session management for structured development workflows.

## What's Included

This template provides:

- **AI Session Management**: Structured prompts and workflows for planning, executing, and documenting development sessions
- **Make Commands**: Simple interface for starting sessions, creating checkpoints, and managing work
- **Session Tracking**: Organized checkpoint system to maintain context across sessions

## Quick Start

### Start a New Session

```bash
make session-start
```

This will:
- Check for previous session checkpoints
- Show planning prompts
- Help you structure your session goal

### During Development

```bash
# Show step-by-step development guide
make ai-step

# View session history
make ai-history
```

### End a Session

```bash
# Create a checkpoint
make session-end

# Commit your work
make session-commit

# Push to remote
make session-push

# Create a pull request
make session-pr
```

## Directory Structure

```
.
├── .ai/                          # AI system
│   ├── prompts/                  # Session prompts
│   │   ├── session-start.md      # Planning phase
│   │   ├── planning-prompt.md    # Simplified planning
│   │   ├── execution-prompt.md   # Step-by-step execution
│   │   ├── step-by-step.md       # Development flow guide
│   │   └── session-end.md        # Checkpoint creation
│   ├── templates/                # Checkpoint templates
│   │   └── session-checkpoint-template.md
│   └── sessions/                 # Your checkpoints
│       └── {developer}/{date}/session-*.md
├── .project/scripts/session/     # Session management scripts
├── Makefile                      # Make commands
└── README.md                     # This file
```

## Available Commands

### Session Management (High-level)

| Command | Description |
|---------|-------------|
| `make session-start` | Start a new development session (recommended) |
| `make session-end` | End current session and create checkpoint |
| `make session-commit` | Commit session work (add SKIP_VERIFY=1 to skip hooks) |
| `make session-push` | Push session work to remote |
| `make session-pr` | Create pull request with auto-generated content |

### AI Development (Low-level)

| Command | Description |
|---------|-------------|
| `make ai-start` | Start AI session (shows checkpoint + prompt) |
| `make ai-step` | Show step-by-step development prompt |
| `make ai-checkpoint` | Create session checkpoint |
| `make ai-history` | Show recent AI session history |

## How It Works

### 1. Planning Phase

When you run `make session-start`, you'll:
- State your session goal
- Optionally continue from a previous checkpoint
- Receive structured prompts to plan your work

### 2. Execution Phase

During development:
- Follow step-by-step guidance from AI prompts
- Implement components one at a time
- Maintain alignment with your architecture

### 3. Checkpoint Phase

When you run `make session-end`, you'll:
- Create a comprehensive checkpoint document
- Record what was accomplished
- Note key decisions and next steps
- Preserve context for future sessions

## Session Workflow

```
┌──────────────┐
│ session-start│  Plan your work, set goals
└──────┬───────┘
       │
       v
┌──────────────┐
│  Development │  Implement using AI guidance
└──────┬───────┘
       │
       v
┌──────────────┐
│ session-end  │  Create checkpoint
└──────┬───────┘
       │
       v
┌──────────────┐
│session-commit│  Commit your changes
└──────┬───────┘
       │
       v
┌──────────────┐
│ session-push │  Push to remote
└──────────────┘
```

## Customization

You can customize the AI prompts in `.ai/prompts/` to match your workflow and coding standards.

## License

This template is provided as-is for use in your projects.
