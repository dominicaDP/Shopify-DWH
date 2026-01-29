# Platform-Specific MCP Setup Issues

Detailed troubleshooting for operating system-specific MCP server issues.

## macOS

### Issue 1: Gatekeeper Blocking uv Binary

**Symptoms:**
- "uv" cannot be opened because the developer cannot be verified
- "malicious software" warning when running uv commands
- Permission denied errors

**Solutions:**

**Method 1: Remove Quarantine Attribute**
```bash
# Remove quarantine attribute from uv binary
xattr -d com.apple.quarantine ~/.local/bin/uv

# Verify it was removed
xattr -l ~/.local/bin/uv  # Should show no quarantine attribute
```

**Method 2: System Settings**
1. Open System Settings
2. Go to Privacy & Security
3. Scroll to "Security" section
4. Click "Allow Anyway" next to the uv warning
5. Try running uv command again
6. Click "Open" when prompted

**Method 3: Disable Gatekeeper (Not Recommended)**
```bash
# Disable Gatekeeper (requires admin password)
sudo spctl --master-disable

# After running uv, re-enable for security
sudo spctl --master-enable
```

### Issue 2: Python Version Management

**Problem:** Multiple Python versions installed via Homebrew

**Check Current Version:**
```bash
python3 --version
which python3
```

**Install Specific Version:**
```bash
# Install Python 3.10 or higher
brew install python@3.10

# Set as default (add to ~/.zshrc or ~/.bash_profile)
export PATH="/opt/homebrew/opt/python@3.10/bin:$PATH"

# Reload shell
source ~/.zshrc  # or source ~/.bash_profile
```

### Issue 3: File Permissions

**Problem:** Cannot write to Claude config directory

**Fix:**
```bash
# Check directory permissions
ls -la ~/Library/Application\ Support/Claude/

# Fix permissions if needed
chmod 755 ~/Library/Application\ Support/Claude/
chmod 644 ~/Library/Application\ Support/Claude/claude_desktop_config.json

# Create directory if missing
mkdir -p ~/Library/Application\ Support/Claude/
```

### macOS Configuration Paths

```
# Config file
~/Library/Application Support/Claude/claude_desktop_config.json

# Log files
~/Library/Logs/Claude/mcp*.log

# uv installation
~/.local/bin/uv
```

## Windows

### Issue 1: PowerShell Execution Policy

**Symptoms:**
- Scripts cannot be executed
- "cannot be loaded because running scripts is disabled" error
- Access denied when running uv

**Check Current Policy:**
```powershell
Get-ExecutionPolicy
```

**Fix (Run PowerShell as Administrator):**

**Method 1: User Scope (Recommended)**
```powershell
# Allow scripts for current user only
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# Verify change
Get-ExecutionPolicy -List
```

**Method 2: Process Scope (Temporary)**
```powershell
# Only affects current PowerShell session
Set-ExecutionPolicy Bypass -Scope Process

# Will reset when you close PowerShell
```

**Method 3: System-Wide (Requires Admin)**
```powershell
# Run PowerShell as Administrator
Set-ExecutionPolicy RemoteSigned -Scope LocalMachine

# WARNING: Affects all users on system
```

### Issue 2: PATH Environment Variable

**Problem:** uv command not found

**Add to PATH:**

**Method 1: GUI**
1. Right-click Start → System
2. Advanced system settings
3. Environment Variables
4. Edit "Path" under User variables
5. Add: `%USERPROFILE%\.local\bin`
6. Click OK, restart terminal

**Method 2: PowerShell**
```powershell
# Add to user PATH
$env:Path += ";$env:USERPROFILE\.local\bin"

# Make permanent (add to PowerShell profile)
echo '$env:Path += ";$env:USERPROFILE\.local\bin"' >> $PROFILE
```

### Issue 3: WSL2 Integration (Recommended)

**Why WSL2?**
- Better compatibility with Linux-based MCP servers
- Native Python environment
- Avoid Windows-specific path issues

**Setup:**
```powershell
# Install WSL2 (run as Administrator)
wsl --install

# Install Ubuntu (or preferred distro)
wsl --install -d Ubuntu

# Launch WSL2
wsl

# Inside WSL2, follow Linux setup instructions
```

**File Path Translation:**
```bash
# Windows: C:\Users\username\Documents
# WSL2:    /mnt/c/Users/username/Documents

# Access Windows files from WSL2
cd /mnt/c/Users/username/Documents

# Access WSL2 files from Windows
\\wsl$\Ubuntu\home\username
```

**Git Configuration in WSL2:**
```bash
# Prevent line ending issues
git config --global core.autocrlf false
git config --global core.eol lf
```

### Issue 4: Python Installation

**Problem:** Python not installed or wrong version

**Check Version:**
```powershell
python --version
# Or
python3 --version
```

**Install Python 3.10+:**

**Method 1: Official Installer**
1. Download from https://www.python.org/downloads/
2. Run installer
3. ✅ Check "Add Python to PATH"
4. Click "Install Now"
5. Restart terminal

**Method 2: Winget (Windows Package Manager)**
```powershell
# Install Python 3.10
winget install Python.Python.3.10

# Verify installation
python --version
```

### Windows Configuration Paths

```
# Config file
%APPDATA%\Claude\claude_desktop_config.json
# Expanded: C:\Users\username\AppData\Roaming\Claude\claude_desktop_config.json

# Log files
%APPDATA%\Claude\Logs\mcp*.log

# uv installation
%USERPROFILE%\.local\bin\uv.exe
# Expanded: C:\Users\username\.local\bin\uv.exe
```

### Issue 5: Multiline Input in PowerShell

**Problem:** Cannot enter multiline JSON in terminal

**Solution:**
```powershell
# Use Shift+Enter or Alt+Enter for newlines in PowerShell
# Or use a text editor and pipe:

# Create config in Notepad
notepad claude_desktop_config.json

# Or use VS Code
code %APPDATA%\Claude\claude_desktop_config.json
```

## Linux

### Issue 1: Missing Python Dependencies

**Symptoms:**
- Python command not found
- "No module named pip" error
- Build failures during package installation

**Ubuntu/Debian:**
```bash
# Update package list
sudo apt update

# Install Python 3.10 and dependencies
sudo apt install python3.10 python3.10-venv python3-pip

# Verify installation
python3.10 --version
```

**Fedora/RHEL:**
```bash
# Install Python 3.10
sudo dnf install python310 python3-pip

# Verify installation
python3.10 --version
```

**Arch Linux:**
```bash
# Install Python
sudo pacman -S python python-pip

# Verify installation
python --version
```

### Issue 2: uv Installation Issues

**Problem:** uv not in PATH after installation

**Check Installation:**
```bash
# Verify uv is installed
ls -la ~/.local/bin/uv

# Check if ~/.local/bin is in PATH
echo $PATH | grep ".local/bin"
```

**Add to PATH:**
```bash
# Add to ~/.bashrc or ~/.zshrc
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# Reload shell config
source ~/.bashrc

# Verify
which uv
```

### Issue 3: Permission Issues

**Problem:** Cannot write to config directory

**Fix Permissions:**
```bash
# Check directory permissions
ls -la ~/.config/Claude/

# Create directory if missing
mkdir -p ~/.config/Claude/

# Fix permissions
chmod 755 ~/.config/Claude/
chmod 644 ~/.config/Claude/claude_desktop_config.json
```

### Issue 4: System Dependencies for MCP Servers

**Problem:** Missing system libraries for certain MCP servers

**Common Dependencies:**
```bash
# Ubuntu/Debian
sudo apt install build-essential libssl-dev libffi-dev

# Fedora
sudo dnf install gcc openssl-devel libffi-devel

# Arch
sudo pacman -S base-devel openssl
```

### Linux Configuration Paths

```
# Config file
~/.config/Claude/claude_desktop_config.json

# Log files
~/.config/Claude/logs/mcp*.log

# uv installation
~/.local/bin/uv
```

### Issue 5: tmux/screen Compatibility

**Using Claude Code in tmux/screen:**

```bash
# Works natively in tmux
tmux new -s claude-session

# Works natively in screen
screen -S claude-session

# No special configuration needed
```

### Issue 6: Speech Recognition (Voice Input)

**Problem:** No built-in voice input like macOS

**Solutions:**

**Option 1: Browser-based (Easiest)**
- Use Claude web version for voice features
- Chrome/Firefox support Web Speech API

**Option 2: Install Voice Recognition**

**Ubuntu:**
```bash
# Install speech recognition
sudo apt install gnome-shell-extension-desktop-icons-ng

# Or use external tools
# - Google Docs voice typing (browser)
# - Voice In browser extension
```

**Fedora:**
```bash
# Install speech packages
sudo dnf install speech-dispatcher espeak-ng
```

## Cross-Platform Issues

### Issue 1: JSON Syntax Validation

**Works on all platforms:**

```bash
# Using Python (installed on most systems)
python3 -c "import json; json.load(open('claude_desktop_config.json'))" && echo "Valid JSON" || echo "Invalid JSON"

# Using Node.js (if installed)
node -e "console.log(JSON.parse(require('fs').readFileSync('claude_desktop_config.json')))"

# Online validators (copy/paste)
# https://jsonlint.com/
# https://jsonformatter.org/
```

### Issue 2: Line Endings

**Problem:** Config file has wrong line endings (CRLF vs LF)

**Check Line Endings:**
```bash
# macOS/Linux
file claude_desktop_config.json

# Expected: "ASCII text"
# Problem: "ASCII text, with CRLF line terminators"
```

**Fix Line Endings:**

**macOS/Linux:**
```bash
# Convert CRLF to LF
dos2unix claude_desktop_config.json

# Or using sed
sed -i 's/\r$//' claude_desktop_config.json
```

**Windows (Git Bash):**
```bash
# Convert to LF
dos2unix claude_desktop_config.json

# Or in PowerShell
(Get-Content claude_desktop_config.json) | Set-Content -NoNewline claude_desktop_config.json
```

### Issue 3: File Encoding

**Problem:** Config file not UTF-8 encoded

**Check Encoding:**
```bash
# macOS/Linux
file -I claude_desktop_config.json

# Expected: "charset=utf-8"
```

**Fix Encoding:**
```bash
# Convert to UTF-8
iconv -f ISO-8859-1 -t UTF-8 claude_desktop_config.json > claude_desktop_config_utf8.json
mv claude_desktop_config_utf8.json claude_desktop_config.json
```

## Platform Comparison

| Feature | macOS | Windows | Linux |
|---------|-------|---------|-------|
| **Native Support** | ✅ Full | ⚠️ WSL2 recommended | ✅ Full |
| **Voice Input** | ✅ Built-in (Fn Fn) | ⚠️ Win+H (limited) | ❌ Browser only |
| **Terminal** | ✅ Terminal.app, iTerm2 | ⚠️ PowerShell, WSL2 | ✅ Native |
| **Python** | ✅ Pre-installed | ❌ Must install | ✅ Usually pre-installed |
| **uv Installation** | ✅ Easy | ⚠️ PATH issues | ✅ Easy |
| **Config Path** | `~/Library/Application Support/` | `%APPDATA%\` | `~/.config/` |
| **Common Issues** | Gatekeeper blocking | Execution policy | Dependencies |

## Quick Platform-Specific Diagnosis

### macOS Quick Check
```bash
# Verify Python
python3 --version  # Should be 3.10+

# Verify uv
which uv  # Should show ~/.local/bin/uv

# Check Gatekeeper
xattr -l ~/.local/bin/uv  # Should show no quarantine

# Verify config
cat ~/Library/Application\ Support/Claude/claude_desktop_config.json | python3 -m json.tool
```

### Windows Quick Check
```powershell
# Verify Python
python --version  # Should be 3.10+

# Verify uv
where.exe uv  # Should show path to uv.exe

# Check execution policy
Get-ExecutionPolicy  # Should be RemoteSigned or Unrestricted

# Verify config
Get-Content $env:APPDATA\Claude\claude_desktop_config.json | python -m json.tool
```

### Linux Quick Check
```bash
# Verify Python
python3 --version  # Should be 3.10+

# Verify uv
which uv  # Should show ~/.local/bin/uv

# Check PATH
echo $PATH | grep ".local/bin"  # Should contain ~/.local/bin

# Verify config
cat ~/.config/Claude/claude_desktop_config.json | python3 -m json.tool
```

## Related References

- See `troubleshooting.md` for general MCP issues
- See `configuration-patterns.md` for config examples
- See `validation-script.md` for automated validation
- See `../SKILL.md` for setup instructions
