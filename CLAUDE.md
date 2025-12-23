# Claude Code Agent Instructions

## Context and Token Management

### Monitor Usage Proactively

You MUST actively monitor context window and token usage throughout the session:

1. **Check Regularly**: After every 3-5 tool calls, check your current token usage
2. **Warn Early**: Alert the user when reaching these thresholds:
   - ⚠️ **50% usage** (100k/200k tokens): Inform user of current usage
   - ⚠️ **70% usage** (140k/200k tokens): Warn that we're approaching limits, suggest checkpoint
   - 🚨 **85% usage** (170k/200k tokens): Strong warning, recommend creating session checkpoint NOW
   - 🚨 **95% usage** (190k/200k tokens): Critical - must create checkpoint immediately

### Warning Format

When warning the user about token usage, use this format:

```
⚠️ **Context Usage Alert**

Current usage: XXk/200k tokens (XX%)

Recommendation: [Your specific recommendation based on threshold]

Actions available:
- `make session-end` - Create checkpoint and end session
- Continue with current session (not recommended above 85%)
```

### Checkpoint Recommendations

When approaching limits (>70%), recommend:

1. **Create a checkpoint** using `make session-end`
2. **Commit current work** to preserve progress
3. **Start a fresh session** to continue with full context
4. **Reference the checkpoint** in the new session for continuity

### Best Practices

- **Never** let the session exceed 95% without explicit user override
- **Prioritize** creating checkpoints over continuing when >85%
- **Remind** users that checkpoints preserve context for next session
- **Suggest** breaking large tasks into multiple sessions when planning
- **Track** cumulative token usage across tool calls

### Session Planning

When starting a session (via `make session-start`):

1. Check if the planned work fits in available context
2. If the goal seems large, suggest breaking into multiple sessions
3. Plan checkpoint milestones proactively

### Example Warnings

**At 50%:**
```
ℹ️ Context usage: 100k/200k tokens (50%)
We're halfway through the available context. Session is healthy.
```

**At 70%:**
```
⚠️ Context usage: 140k/200k tokens (70%)
We're approaching context limits. Consider creating a checkpoint soon
with `make session-end` to preserve progress.
```

**At 85%:**
```
🚨 Context usage: 170k/200k tokens (85%)
We're very close to context limits!

Recommendation: Create a checkpoint NOW before we lose context.

Run:
1. `make session-end` - Create checkpoint
2. Commit your changes
3. Start fresh session with `make session-start`
```

**At 95%:**
```
🚨 CRITICAL: Context usage: 190k/200k tokens (95%)
Context window nearly exhausted!

You MUST create a checkpoint immediately:
`make session-end`

Without a checkpoint, we risk losing context and session continuity.
```

## General Behavior

### Communication Style

- Be concise and clear
- Avoid unnecessary explanations unless asked
- Focus on solving the problem efficiently
- Use the TODO system to track complex tasks

### Tool Usage

- Use tools efficiently to minimize token usage
- Batch parallel operations when possible
- Avoid redundant file reads
- Leverage the Task tool for complex searches

### Session Hygiene

- Keep sessions focused on single goals
- Create checkpoints at logical milestones
- Don't try to accomplish too much in one session
- Preserve context through good checkpoint documentation

---

**Remember**: The goal is to maintain productive sessions while respecting context limits. Proactive checkpoint management is key to long-term project success.
