# Complete Installation Guide: Second Brain from Scratch

**Time Required:** 30-45 minutes
**Skill Level:** Beginner-friendly

This guide walks through every step to install Claude Code and set up the Second Brain system on a fresh computer.

---

## Table of Contents

1. [Prerequisites Overview](#1-prerequisites-overview)
2. [Install Node.js](#2-install-nodejs)
3. [Install Git](#3-install-git)
4. [Install a Code Editor](#4-install-a-code-editor)
5. [Install Claude Code CLI](#5-install-claude-code-cli)
6. [Authenticate Claude Code](#6-authenticate-claude-code)
7. [Get the Second Brain Repository](#7-get-the-second-brain-repository)
8. [Customize for Your Use](#8-customize-for-your-use)
9. [Verify Installation](#9-verify-installation)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Prerequisites Overview

You'll need to install:

| Software | Purpose | Required |
|----------|---------|----------|
| Node.js | Runs Claude Code CLI | Yes |
| Git | Version control | Yes |
| Code Editor | Edit files | Recommended |
| Claude Account | Authentication | Yes |

**Supported Platforms:**
- Windows 10/11
- macOS 10.15+
- Linux (Ubuntu 20.04+, Debian, Fedora)

---

## 2. Install Node.js

Claude Code requires Node.js version 18 or higher.

### Windows

**Option A: Direct Download (Easiest)**
1. Go to https://nodejs.org/
2. Download the **LTS** version (green button)
3. Run the installer
4. Accept all defaults, click Next through the wizard
5. **Important:** Check "Automatically install necessary tools" if prompted

**Option B: Using winget (Windows 11)**
```powershell
winget install OpenJS.NodeJS.LTS
```

### macOS

**Option A: Direct Download**
1. Go to https://nodejs.org/
2. Download the **LTS** version for macOS
3. Run the .pkg installer
4. Follow the prompts

**Option B: Using Homebrew (Recommended)**
```bash
# Install Homebrew first if you don't have it
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Then install Node.js
brew install node@20
```

### Linux (Ubuntu/Debian)

```bash
# Update package list
sudo apt update

# Install Node.js 20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

### Verify Installation

Open a new terminal/command prompt and run:

```bash
node --version
```

You should see `v18.x.x` or higher (e.g., `v20.11.0`).

Also verify npm:
```bash
npm --version
```

You should see `9.x.x` or higher.

---

## 3. Install Git

### Windows

**Option A: Direct Download (Easiest)**
1. Go to https://git-scm.com/download/win
2. Download will start automatically
3. Run the installer
4. **Recommended settings during install:**
   - Default editor: Choose your preference (VS Code if installed)
   - PATH environment: "Git from the command line and also from 3rd-party software"
   - HTTPS transport backend: "Use the OpenSSL library"
   - Line ending conversions: "Checkout Windows-style, commit Unix-style"
   - Terminal emulator: "Use Windows' default console"
   - Default behavior of `git pull`: "Default (fast-forward or merge)"
   - Credential helper: "Git Credential Manager"
   - Accept defaults for everything else

**Option B: Using winget**
```powershell
winget install Git.Git
```

### macOS

**Option A: Xcode Command Line Tools (Easiest)**
```bash
xcode-select --install
```
Click "Install" when prompted.

**Option B: Using Homebrew**
```bash
brew install git
```

### Linux (Ubuntu/Debian)

```bash
sudo apt update
sudo apt install git
```

### Verify Installation

Open a **new** terminal and run:

```bash
git --version
```

You should see `git version 2.x.x` (e.g., `git version 2.43.0`).

### Configure Git (Required)

Set your name and email (used for commits):

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

**Windows users:** Also run:
```bash
git config --global core.autocrlf false
```

---

## 4. Install a Code Editor

You need a text editor to edit configuration files. **VS Code** is recommended.

### Visual Studio Code (Recommended)

**Windows:**
1. Go to https://code.visualstudio.com/
2. Download and run the installer
3. Accept defaults

**macOS:**
```bash
brew install --cask visual-studio-code
```

**Linux:**
```bash
sudo snap install code --classic
```

### Alternative Editors

- **Sublime Text:** https://www.sublimetext.com/
- **Notepad++** (Windows): https://notepad-plus-plus.org/
- **vim/nano** (already installed on macOS/Linux)

---

## 5. Install Claude Code CLI

Now install Claude Code globally using npm.

### All Platforms

Open terminal/command prompt and run:

```bash
npm install -g @anthropic-ai/claude-code
```

**Note:** On macOS/Linux, if you get permission errors, either:

**Option A: Fix npm permissions (Recommended)**
```bash
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
# Then retry the install
npm install -g @anthropic-ai/claude-code
```

**Option B: Use sudo (Not recommended but works)**
```bash
sudo npm install -g @anthropic-ai/claude-code
```

### Verify Installation

```bash
claude --version
```

You should see the Claude Code version number.

---

## 6. Authenticate Claude Code

Claude Code needs to authenticate with your Anthropic account.

### Option A: Claude Pro/Max Subscription (Easiest)

If you have a Claude Pro or Max subscription:

1. Run Claude Code:
   ```bash
   claude
   ```

2. It will open a browser window for authentication
3. Log in with your Claude account
4. Authorize the connection
5. Return to terminal - you're authenticated!

### Option B: API Key

If you have an Anthropic API key:

1. Get your API key from https://console.anthropic.com/
2. Set it as an environment variable:

**Windows (PowerShell):**
```powershell
$env:ANTHROPIC_API_KEY = "your-api-key-here"
```

**Windows (Command Prompt):**
```cmd
set ANTHROPIC_API_KEY=your-api-key-here
```

**macOS/Linux:**
```bash
export ANTHROPIC_API_KEY="your-api-key-here"
```

To make it permanent:

**Windows:** Add to System Environment Variables
1. Search "Environment Variables" in Start menu
2. Click "Environment Variables"
3. Under "User variables", click "New"
4. Variable name: `ANTHROPIC_API_KEY`
5. Variable value: your API key

**macOS/Linux:** Add to shell profile
```bash
echo 'export ANTHROPIC_API_KEY="your-api-key-here"' >> ~/.bashrc
source ~/.bashrc
```

### Verify Authentication

```bash
claude
```

If it starts without errors, you're authenticated. Type `/exit` to quit.

---

## 7. Get the Second Brain Repository

### Option A: Clone from Git (If Hosted)

If the Second Brain is in a Git repository:

```bash
# Navigate to where you want the folder
cd ~/Documents  # or wherever you prefer

# Clone the repository
git clone https://github.com/YOUR_USERNAME/second-brain.git

# Enter the directory
cd second-brain
```

### Option B: Copy from USB/Folder

If you received the files directly:

1. Copy the `TEMPLATE` folder to your desired location
2. Rename it to `second-brain` (or your preferred name)
3. Open terminal and navigate to it:

**Windows:**
```powershell
cd C:\Users\YourName\Documents\second-brain
```

**macOS/Linux:**
```bash
cd ~/Documents/second-brain
```

### Option C: Download as ZIP

If downloading from GitHub:

1. Go to the repository page
2. Click "Code" → "Download ZIP"
3. Extract the ZIP file
4. Navigate to the extracted folder in terminal

### Initialize Git (If Not Already a Repo)

If the folder isn't already a Git repository:

```bash
cd second-brain
git init
git add .
git commit -m "Initial commit: Second Brain setup"
```

---

## 8. Customize for Your Use

### Step 1: Edit CLAUDE.md

This is the most important file. Open it in your editor:

```bash
code CLAUDE.md  # Opens in VS Code
```

Find the **User Profile** section and fill in:

```markdown
## User Profile

**Role & Context:**
- [Your job title, e.g., "Software Developer"]
- [Company type, e.g., "Startup, 20 people"]
- [Primary focus, e.g., "Backend development"]
- [Platform, e.g., "Windows 11"]

**Work Domains:**
- [Primary language, e.g., "Python"]
- [Framework, e.g., "FastAPI"]
- [Other work, e.g., "Data analysis"]

**Pain Points:**
- [e.g., "Losing context between sessions"]
- [e.g., "Repetitive boilerplate code"]

**Tech Stack:**
- IDE: [e.g., "VS Code"]
- Language: [e.g., "Python 3.11"]
- Database: [e.g., "PostgreSQL"]

**Goals (6 months):**
- [e.g., "Ship MVP of side project"]
- [e.g., "Learn testing best practices"]
```

### Step 2: Configure Permissions

Edit `settings.local.json` to add your development tools:

```bash
code settings.local.json
```

Add your tools to the `allow` list. Examples:

**For Python developers:**
```json
"Bash(python *:*)",
"Bash(python3 *:*)",
"Bash(pip *:*)",
"Bash(pytest *:*)",
"Bash(poetry *:*)",
"Bash(uvicorn *:*)"
```

**For JavaScript/TypeScript developers:**
```json
"Bash(npm *:*)",
"Bash(npx *:*)",
"Bash(node *:*)",
"Bash(yarn *:*)",
"Bash(pnpm *:*)"
```

**For Go developers:**
```json
"Bash(go *:*)",
"Bash(make *:*)"
```

**For Rust developers:**
```json
"Bash(cargo *:*)",
"Bash(rustc *:*)"
```

**For .NET/C# developers:**
```json
"Bash(dotnet *:*)",
"Bash(nuget *:*)"
```

### Step 3: Create Your First Project

```bash
# Create project directory
mkdir -p projects/my-project

# Copy template files
cp projects/_template/* projects/my-project/
```

Edit the files in `projects/my-project/` with your actual project info.

### Step 4: Update Projects Index

Edit `projects/INDEX.md` to add your project:

```markdown
## Active Projects

| Project | Type | Status | Priority | Health |
|---------|------|--------|----------|--------|
| my-project | Personal | Active | HIGH | Healthy |
```

---

## 9. Verify Installation

### Test 1: Start Claude Code

```bash
cd /path/to/second-brain
claude
```

You should see the Claude Code interface start.

### Test 2: Check Overview

In Claude Code, type:
```
/overview
```

You should see your tasks dashboard (may be empty initially).

### Test 3: Switch to Project

```
/switch my-project
```

You should see your project context loaded.

### Test 4: Test Learning

```
/learn
```

It should ask you questions about completed work.

### Exit Claude Code

Type `/exit` or press `Ctrl+C` to quit.

---

## 10. Troubleshooting

### "claude: command not found"

**Cause:** npm global bin not in PATH

**Windows:** Close and reopen terminal, or:
```powershell
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
```

**macOS/Linux:**
```bash
# Find where npm installs global packages
npm config get prefix

# Add to PATH (replace /usr/local with your prefix)
export PATH="/usr/local/bin:$PATH"
```

### "npm ERR! permission denied"

**macOS/Linux:** Fix npm permissions:
```bash
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

### "Authentication failed"

1. Check your internet connection
2. Try logging in at https://claude.ai first
3. Clear credentials and retry:
   ```bash
   claude logout
   claude
   ```

### "CLAUDE.md not found" or commands don't work

Make sure you're in the second-brain directory:
```bash
pwd  # Should show /path/to/second-brain
ls   # Should show CLAUDE.md, settings.local.json, etc.
```

### Git errors on Windows

If you see line ending warnings:
```bash
git config --global core.autocrlf false
```

### "spawn ENOENT" errors

A tool in your PATH isn't found. Check that the tool exists:
```bash
which git    # Should return a path
which node   # Should return a path
```

### Commands return errors

1. Check file exists: `ls .claude/commands/`
2. Check YAML frontmatter syntax in command files
3. Restart Claude Code

### Still stuck?

1. Check Claude Code issues: https://github.com/anthropics/claude-code/issues
2. Verify all prerequisites are installed correctly
3. Try a fresh install in a new directory

---

## Quick Reference Card

### Daily Commands

| Command | What it does |
|---------|--------------|
| `claude` | Start Claude Code |
| `/overview` | See all tasks |
| `/switch [project]` | Load project context |
| `/plan [goal]` | Plan complex tasks |
| `/step` | Execute next step |
| `/learn` | Extract patterns |
| `/exit` | Quit Claude Code |

### File Locations

| File | Purpose |
|------|---------|
| `CLAUDE.md` | System instructions (customize User Profile) |
| `settings.local.json` | Permissions (add your tools) |
| `projects/[name]/` | Your project files |
| `memory/` | Knowledge storage |

### Getting Help

- In Claude Code: `/help`
- Documentation: https://docs.anthropic.com/claude-code
- Issues: https://github.com/anthropics/claude-code/issues

---

## Next Steps

1. **Read ONBOARDING.md** for the full setup guide
2. **Run `/overview`** each morning
3. **Run `/learn`** after completing work
4. **Check `/grow`** weekly for brain health

**You're ready to start using your Second Brain!**
