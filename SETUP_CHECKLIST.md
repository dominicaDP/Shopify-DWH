# Second Brain Setup Checklist

This package is ready to use. Follow this checklist to customize it for your needs.

---

## What's Included

This export contains everything you need:

```
EXPORT/
├── CLAUDE.md                 # System instructions (CUSTOMIZE THIS)
├── README.md                 # Quick start guide
├── ONBOARDING.md             # Detailed setup guide
├── INSTALLATION_GUIDE.md     # Install prerequisites
├── settings.local.json       # Permissions (add your tools)
├── .claude/
│   ├── commands/             # All slash commands
│   ├── skills/               # All workflows
│   ├── agents/               # All AI agents
│   └── hooks/                # Event hooks
├── memory/                   # Empty knowledge storage
├── projects/                 # Project templates
└── brain-health/             # Metrics tracking
```

---

## Setup Steps

### Step 1: Install Prerequisites

Follow `INSTALLATION_GUIDE.md` to install:
- [ ] Node.js (v18+)
- [ ] Git
- [ ] Claude Code CLI (`npm install -g @anthropic-ai/claude-code`)

### Step 2: Copy This Folder

Copy the entire EXPORT folder to your desired location:

**Windows:**
```powershell
Copy-Item -Path "EXPORT" -Destination "C:\Users\YourName\second-brain" -Recurse
```

**macOS/Linux:**
```bash
cp -r EXPORT ~/second-brain
```

### Step 3: Customize CLAUDE.md (Required)

Open `CLAUDE.md` and fill in the **User Profile** section:

| Section | What to Add |
|---------|-------------|
| Role & Context | Your job, company, work focus |
| Work Domains | Languages, frameworks, types of work |
| Pain Points | What frustrates you |
| Tech Stack | IDE, language, database, platform |
| Goals | 6-month success vision |

### Step 4: Configure Permissions

Edit `settings.local.json` to add your development tools.

**Python:**
```json
"Bash(python *:*)",
"Bash(pip *:*)",
"Bash(pytest *:*)"
```

**JavaScript/TypeScript:**
```json
"Bash(npm *:*)",
"Bash(node *:*)",
"Bash(yarn *:*)"
```

**Go:**
```json
"Bash(go *:*)",
"Bash(make *:*)"
```

**C#/.NET:**
```json
"Bash(dotnet *:*)",
"Bash(nuget *:*)"
```

**Rust:**
```json
"Bash(cargo *:*)"
```

### Step 5: Create Your First Project

```bash
cd ~/second-brain
mkdir -p projects/my-project
cp projects/_template/* projects/my-project/
```

Edit the files in `projects/my-project/` with your actual project info.

### Step 6: Update Projects Index

Edit `projects/INDEX.md` to add your project.

### Step 7: Initialize Git

```bash
cd ~/second-brain
git init
git add .
git commit -m "Initial commit: Second Brain setup"
```

### Step 8: Test It

```bash
claude
/overview
/switch my-project
```

---

## Customization Summary

| File | Required? | What to Do |
|------|-----------|------------|
| `CLAUDE.md` | **Yes** | Fill in User Profile |
| `settings.local.json` | **Yes** | Add your dev tools |
| `projects/INDEX.md` | Yes | Add your projects |
| `projects/my-project/*` | Yes | Create first project |
| `memory/semantic/tech/*` | Recommended | Document your stack |

---

## Verification Checklist

After setup, verify:

- [ ] `claude` command works in the directory
- [ ] `/overview` runs without errors
- [ ] `/switch my-project` loads your project
- [ ] Your tech stack is in `settings.local.json`
- [ ] User Profile is filled in `CLAUDE.md`

---

## Next Steps

1. Read `ONBOARDING.md` for the full usage guide
2. Run `/overview` each morning
3. Run `/learn` after completing work
4. Check `/grow` weekly for brain health

**You're ready to start using your Second Brain!**
