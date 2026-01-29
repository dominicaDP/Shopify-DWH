#!/bin/bash
#
# UserPromptSubmit Hook
# Runs before every user prompt to provide context-aware micro-guidance
#
# Optimized for minimal context bloat (≤6 lines, ~150 chars max)
# Rotates reminders by phase to stay relevant

# Get the user's prompt
USER_PROMPT="$1"

# Check if plan exists
PLAN_FILE=".claude-plan.json"
HAS_PLAN=false
if [ -f "$PLAN_FILE" ]; then
  HAS_PLAN=true
fi

# Determine current phase based on context
PHASE="execution"  # Default

# Phase detection logic
if [[ "$USER_PROMPT" =~ (setup|install|configure|init) ]]; then
  PHASE="setup"
elif [[ "$USER_PROMPT" =~ (plan|organize|structure|break down) ]]; then
  PHASE="planning"
elif [[ "$USER_PROMPT" =~ (review|check|verify|test|grow) ]]; then
  PHASE="review"
elif [[ "$USER_PROMPT" =~ (write|edit|create|build|implement|add|fix) ]] && [ "$HAS_PLAN" = false ]; then
  PHASE="pre-execution"
fi

# Generate phase-appropriate reminder (≤6 lines)
case "$PHASE" in
  setup)
    cat <<'EOF'
💡 Quick tip:
• Validate MCP connections with server health checks
• Check platform (Windows/WSL/Mac) for OS-specific notes
• Start with minimal setup, add complexity incrementally
EOF
    ;;

  planning)
    cat <<'EOF'
💡 Quick tip:
• For tasks >15 min: /plan breaks into ≤10 min steps
• Check current project: Read projects/CURRENT
• Load context: Read projects/[name]/context.md + tasks.md
EOF
    ;;

  pre-execution)
    cat <<'EOF'
⚠️  Complex task detected:
• Create plan first: /plan [your goal]
• Then execute incrementally: /step
• Prevents context drift & manages rate limits
EOF
    ;;

  execution)
    if [ "$HAS_PLAN" = true ]; then
      cat <<'EOF'
✅ Active plan detected:
• Execute next step: /step
• Check progress: /plan-status
• Incremental checkpoints save progress
EOF
    else
      cat <<'EOF'
💡 Quick tip:
• Check active project context before making changes
• Use /step for incremental execution
• Run /learn after completing work
EOF
    fi
    ;;

  review)
    cat <<'EOF'
💡 Quick tip:
• After completing work: /learn to extract patterns
• Check brain health: /grow
• Archive completed plans, update project status
EOF
    ;;
esac

# Exit successfully (don't block prompt)
exit 0
