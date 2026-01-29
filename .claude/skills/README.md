# Skills Framework

This second brain uses **9 specialized Skills** that activate automatically based on your intent.

## What Are Skills?

Skills are modular AI capabilities with:
- **SKILL.md**: Instructions for Claude
- **references/**: Supporting documentation loaded on-demand
- **examples/**: Real-world usage patterns
- **tests/**: Validation scenarios

Skills use **progressive disclosure** - Claude reads the main SKILL.md (~200 lines), then loads references only when needed.

## Available Skills

### 1. **learn-extraction**
**What**: Extract learnings from completed work and compound knowledge
**When**: After finishing significant work (bug fix, feature, client meeting)
**Output**: Updated pattern in `memory/semantic/`, episodic record
**Command**: `/learn`

### 2. **memory-recall**
**What**: Search across all memory types (semantic, episodic, procedural)
**When**: Need to remember past solutions, patterns, or decisions
**Output**: Relevant memories with context
**Command**: `/recall [topic]`

### 3. **idea-capture**
**What**: Quick capture of ideas with auto-categorization
**When**: Random idea strikes (voice input or text)
**Output**: Idea saved to appropriate project or inbox
**Command**: `/idea [text]`

### 4. **task-management**
**What**: Add, prioritize, and track tasks across projects
**When**: Creating new tasks or managing workload
**Output**: Updated tasks.md in project
**Command**: `/add-task [description]`

### 5. **daily-overview**
**What**: Morning dashboard showing urgent items across all projects
**When**: Start of workday or context refresh needed
**Output**: Prioritized list of what needs attention
**Command**: `/overview`

### 6. **project-creation**
**What**: Scaffold new project with full structure
**When**: Starting new client work or internal project
**Output**: Complete project directory with templates
**Command**: `/new-project [name]`

### 7. **project-switching**
**What**: Zero-overhead context switching between projects
**When**: Moving between different work contexts
**Output**: Updated current project context
**Command**: `/switch [project-name]`

### 8. **brain-health-reporting**
**What**: Growth tracking and ROI metrics
**When**: Weekly review or checking progress
**Output**: Brain health score, patterns learned, time saved
**Command**: `/grow`

### 9. **content-generation**
**What**: Multi-platform content creation with viral patterns
**When**: Creating LinkedIn posts, newsletters, blog content
**Output**: Validated content scored 0-100
**Command**: Use skill directly (no command wrapper)

## How Skills Activate

Skills activate in two ways:

### 1. Via Slash Commands (Most Common)
Bash commands:
- /learn invokes learn-extraction skill
- /recall invokes memory-recall skill
- /overview invokes daily-overview skill

### 2. Automatic Detection (Advanced)
Claude detects your intent and loads the appropriate skill:
- "What did I do yesterday?" triggers memory-recall
- "I just finished the Stripe integration" triggers learn-extraction
- "Show me all my projects" triggers daily-overview

## Skills Architecture

**Commands → Skills → Memory**

1. **Commands** (.claude/commands/*.md) - User-facing slash commands
2. **Skills** (.claude/skills/*/SKILL.md) - Executable workflows
3. **Memory** (memory/) - Knowledge storage

Example flow:
User: /learn
  → Command: .claude/commands/learn.md
  → Skill: .claude/skills/learn-extraction/SKILL.md
  → Memory: memory/semantic/patterns/*.md (updated)

## Skills vs Commands

**Commands are the interface**, **Skills are the implementation**.

- One command can invoke multiple skills
- One skill can be used by multiple commands
- Skills contain the actual logic, commands are thin wrappers

See ../SKILLS_VS_COMMANDS.md for detailed explanation.

## Skills Frontmatter Format

All Skills follow this official structure:

```yaml
---
name: skill-name
description: What it does and when to use it
allowed-tools: "Read,Write,Edit,Grep,Bash"  # Optional
---
```

**Only 3 fields are valid:**
- name (required): lowercase-with-hyphens
- description (required): Includes when to use
- allowed-tools (optional): Comma-separated string

**Common mistakes to avoid:**
- ❌ when_to_use field (merge into description)
- ❌ version field (put in markdown content)
- ❌ Array format: [Read, Write] (use string: "Read,Write")

See official docs: https://docs.anthropic.com/en/docs/agents/skill-authoring-best-practices

## Progressive Disclosure Pattern

Skills use progressive disclosure to manage context efficiently:

learn-extraction/
├── SKILL.md                    # Main instructions (~200 lines)
├── references/
│   ├── examples.md            # Loaded when user needs examples
│   ├── troubleshooting.md     # Loaded when errors occur
│   └── advanced-patterns.md   # Loaded for complex scenarios
└── tests/
    └── validation.md          # Loaded for testing

Claude reads SKILL.md first, then references files only when needed.

## Creating Custom Skills

Want to add your own skill? Follow this pattern:

1. Create skill directory
   mkdir -p .claude/skills/my-new-skill/references

2. Create SKILL.md with proper frontmatter (see format above)

3. Create command wrapper (optional)

4. Test it with /my-command

## Debugging Skills

If a skill doesn't activate:

1. **Check frontmatter syntax**
   - head -10 .claude/skills/skill-name/SKILL.md
   - Verify YAML is valid
   - Only use 3 standard fields
   - No tabs, correct indentation

2. **Verify description is specific**
   - ❌ Vague: "Helps with tasks"
   - ✅ Specific: "Extracts learnings from completed work. Use after finishing bugs, features, or meetings."

3. **Check file permissions**
   - ls -la .claude/skills/skill-name/SKILL.md

4. **Test manually**
   - Ask: "What skills are available?"
   - Ask: "Use [skill-name] skill to [task]"

## Skill Metrics

Track your skill usage in /grow:
- Most-used skills
- Time saved per skill
- Patterns extracted
- Brain growth rate

---

**Total Skills**: 9
**Total Files**: 34 (including references, examples, tests)
**Pattern**: Commands → Skills → Memory
**Architecture**: See ../SKILLS_VS_COMMANDS.md
