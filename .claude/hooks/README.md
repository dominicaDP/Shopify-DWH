# Claude Code Hooks

Hooks are shell scripts that run automatically at specific points in Claude Code's lifecycle to provide control, validation, and context injection.

## Overview

**Purpose:** Automatic validation, logging, permissions, and context-aware guidance without manual invocation.

**Current Implementation:** `user-prompt-submit.sh` - Context-aware micro-guidance system

## How Hooks Work

### Execution Flow

1. **Event Trigger** - Claude Code reaches a hook point (e.g., user submits prompt)
2. **Hook Execution** - All matching hooks run in parallel (60s timeout default)
3. **Decision Processing** - Hook outputs JSON to control behavior
4. **Context Injection** - Additional context added to Claude's memory if provided

### Input/Output Format

**Input (via stdin):**
```json
{
  "userPrompt": "User's message text",
  "hookEventName": "UserPromptSubmit"
}
```

**Output (via stdout):**
```json
{
  "decision": "block",  // or null to allow
  "reason": "Explanation if blocking",
  "hookSpecificOutput": {
    "additionalContext": "Context added to Claude's memory"
  }
}
```

### Environment Variables

All hooks receive:
- `$CLAUDE_PROJECT_DIR` - Current project directory
- `$CLAUDE_FILE_PATHS` - Space-separated relevant file paths
- `$CLAUDE_CODE_REMOTE` - "true" if web environment, empty if CLI

## Available Hook Types

### UserPromptSubmit (Implemented)
- **When:** Before Claude processes user's message
- **Purpose:** Context injection, prompt validation, micro-guidance
- **Can:** Block prompts, add context
- **Current use:** Phase-aware coaching (setup, planning, execution, review)

### PreToolUse
- **When:** Before any tool execution (Read, Write, Bash, etc.)
- **Purpose:** Permission checks, input validation, blocking dangerous operations
- **Can:** Allow/deny/modify tool calls
- **Potential use:** Block `rm -rf`, validate file paths, backup before edits

### PostToolUse
- **When:** After successful tool execution
- **Purpose:** Logging, adding context, post-processing results
- **Can:** Provide additional context to Claude
- **Potential use:** Log all Bash commands, track file changes, learning extraction

### SessionStart
- **When:** Claude Code starts/resumes session
- **Purpose:** Load context, initialize state, setup
- **Can:** Inject initial context
- **Potential use:** Auto-load active project from `projects/CURRENT`

### SessionEnd
- **When:** Session terminates
- **Purpose:** Cleanup tasks, save state, logging
- **Can:** Perform final operations
- **Potential use:** Auto-run `/learn`, save session summary

### PreCompact
- **When:** Before context compaction (memory full)
- **Purpose:** Save important context before compression
- **Can:** Preserve critical information
- **Potential use:** Save active plan state, preserve open tasks

### Stop / SubagentStop / Notification
- **Advanced hooks:** Control continuation, subagent flow, notification handling
- See official docs for details: https://code.claude.com/docs/en/hooks

## Current Implementation: user-prompt-submit.sh

### Purpose
Provides context-aware micro-guidance based on detected workflow phase (≤6 lines, ~150 chars max).

### Phase Detection

The hook analyzes the user's prompt and detects the current phase:

| Phase | Keywords | Guidance Provided |
|-------|----------|-------------------|
| **setup** | setup, install, configure, init | Platform checks, MCP validation, incremental setup |
| **planning** | plan, organize, structure, break down | Use `/plan` for >15 min tasks, load project context |
| **pre-execution** | write, edit, create, build, implement, add, fix (no plan) | ⚠️ Create plan first, prevents context drift |
| **execution** | Default phase | With plan: Use `/step`<br>No plan: Check context, run `/learn` after |
| **review** | review, check, verify, test, grow | Extract patterns with `/learn`, check `/grow` |

### How It Works

```bash
# 1. Receives user prompt as $1 parameter
USER_PROMPT="$1"

# 2. Checks for active plan
if [ -f ".claude-plan.json" ]; then
  HAS_PLAN=true
fi

# 3. Detects phase via keyword matching
if [[ "$USER_PROMPT" =~ (setup|install|configure) ]]; then
  PHASE="setup"
elif [[ "$USER_PROMPT" =~ (plan|organize|structure) ]]; then
  PHASE="planning"
# ... other phases

# 4. Outputs phase-appropriate guidance (3-4 bullet points)
case "$PHASE" in
  setup)
    echo "💡 Quick tip:"
    echo "• Validate MCP connections"
    echo "• Check platform compatibility"
    ;;
  # ... other phases
esac

# 5. Exits successfully (never blocks)
exit 0
```

### Design Principles

1. **Minimal Context Bloat** - ≤6 lines, ~150 characters max
2. **Phase Rotation** - Different reminders based on current work
3. **Just-in-Time Guidance** - Relevant tips when needed
4. **Non-Blocking** - Always exits 0, never prevents execution
5. **Progressive Disclosure** - Simple tips early, complex suggestions when appropriate

### Examples

**User types:** "I want to build a new feature"
**Hook detects:** pre-execution phase (no plan exists)
**Guidance provided:**
```
⚠️  Complex task detected:
• Create plan first: /plan [your goal]
• Then execute incrementally: /step
• Prevents context drift & manages rate limits
```

**User types:** "let me review what we've done"
**Hook detects:** review phase
**Guidance provided:**
```
💡 Quick tip:
• After completing work: /learn to extract patterns
• Check brain health: /grow
• Archive completed plans, update project status
```

## Configuration

Hooks are configured in `settings.local.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/user-prompt-submit.sh",
            "timeout": 60,
            "suppressOutput": false
          }
        ]
      }
    ]
  }
}
```

### Configuration Options

- `type`: "command" (bash) or "prompt" (LLM-based)
- `command`: Shell command to execute
- `timeout`: Seconds before killing hook (default: 60)
- `suppressOutput`: Hide stdout from transcript (default: false)
- `continue`: Whether Claude continues after (default: true)
- `stopReason`: Explanation if continue=false

## Best Practices

### Security
✅ **DO:**
- Validate all inputs from JSON stdin
- Use absolute paths for file operations
- Quote shell variables: `"$variable"`
- Block path traversal (`../`, `/etc/`)
- Review hook code thoroughly

❌ **DON'T:**
- Execute unvalidated user input
- Access sensitive files without validation
- Use `eval` or dynamic execution
- Trust file paths without sanitization
- Store credentials in scripts

### Performance
- Keep hooks fast: aim for <1s execution
- Use `suppressOutput: true` for verbose logs
- Handle errors gracefully with valid JSON output
- Test with `claude --debug` during development

### Patterns

**Conditional execution:**
```bash
# Only run in local CLI environment
if [ -z "$CLAUDE_CODE_REMOTE" ]; then
  # Local-only logic
fi
```

**Safe JSON parsing:**
```bash
INPUT=$(cat)
VALUE=$(echo "$INPUT" | jq -r '.field // "default"')
```

**Error handling:**
```bash
if ! command -v jq &> /dev/null; then
  echo '{"decision": null}' >&2
  exit 0
fi
```

## Testing Hooks

### Manual Testing

```bash
# Test user-prompt-submit hook
./.claude/hooks/user-prompt-submit.sh "I want to build a feature"

# Test with different phases
./.claude/hooks/user-prompt-submit.sh "setup the system"
./.claude/hooks/user-prompt-submit.sh "let me plan this out"
./.claude/hooks/user-prompt-submit.sh "review what we've done"
```

### Debug Mode

```bash
# Enable debug output to see hook execution
claude --debug
```

### Verify Permissions

```bash
# Ensure hook is executable
ls -la .claude/hooks/user-prompt-submit.sh
# Should show: -rwxr-xr-x

# Fix if needed
chmod +x .claude/hooks/user-prompt-submit.sh
```

## Expansion Opportunities

### Potential Future Hooks

**PreToolUse - Safety validation:**
```bash
# Block destructive Bash commands
# Validate file paths before Write
# Backup files before Edit
```

**SessionStart - Context loading:**
```bash
# Auto-load active project from projects/CURRENT
# Initialize session with recent patterns
# Load relevant memory based on time of day
```

**PostToolUse - Learning extraction:**
```bash
# Log all MCP tool usage for pattern analysis
# Track file changes for automatic /learn prompts
# Build usage statistics for /grow metrics
```

**PreCompact - Context preservation:**
```bash
# Save active plan state before compression
# Preserve critical task information
# Archive important conversation context
```

## Comparison: Hooks vs. Skills vs. Commands

| Feature | Hooks | Skills | Commands |
|---------|-------|--------|----------|
| **Trigger** | Automatic (lifecycle events) | Manual (user invokes) | Manual (user types `/cmd`) |
| **Purpose** | Control & automation | Workflows & procedures | User interface |
| **Execution** | Bash/prompt | Claude reads markdown | Claude executes skill |
| **Modifies behavior** | Yes (block/allow/inject) | No (guidance only) | No (guidance only) |
| **Context injection** | Yes (`additionalContext`) | Yes (progressive disclosure) | Yes (frontmatter) |

**When to use:**
- **Hooks:** Automatic validation, permissions, context injection, logging
- **Skills:** Multi-step workflows, domain expertise, reusable procedures
- **Commands:** User-facing shortcuts, orchestration, frequent tasks

## Resources

- **Official Docs:** https://code.claude.com/docs/en/hooks
- **Hooks Guide:** https://code.claude.com/docs/en/hooks-guide
- **Current Implementation:** `.claude/hooks/user-prompt-submit.sh`
- **Configuration:** Root `settings.local.json`

## Troubleshooting

**Hook not firing:**
- Check JSON syntax in `settings.local.json`
- Verify executable permissions: `chmod +x hook-script.sh`
- Test manually: `./hook-script.sh "test input"`

**Invalid JSON output:**
- Use `jq` for safe JSON generation
- Test output: `echo '{}' | ./hook-script.sh | jq`
- Check for stderr contamination (use `>&2` for logs)

**Timeout errors:**
- Increase timeout in settings: `"timeout": 120`
- Check for infinite loops or slow operations
- Add debug logging to identify bottleneck
