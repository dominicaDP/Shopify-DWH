# MCP Troubleshooting Guide

Detailed troubleshooting for common MCP server issues.

## Issue 1: "Server Transport Closed Unexpectedly"

**Symptoms:**
- Server exits immediately after starting
- "Process exiting early" messages

**Common Causes:**

1. **Missing required arguments**
   ```bash
   # Test manually to see error
   uv tool run server-name --help
   ```

2. **Python version too old**
   ```bash
   python3 --version  # Must be 3.10+
   ```

3. **Port conflicts (local servers)**
   ```bash
   # Check if port is in use (macOS/Linux)
   lsof -i :8080
   ```

**Solutions:**

```bash
# Verify all required arguments present
uv tool run server-name --help

# Update Python if needed
brew install python@3.10  # macOS
sudo apt install python3.10  # Linux

# Use different port if conflict
# Add to args: "--port", "8081"
```

## Issue 2: Configuration File Problems

**Invalid JSON Syntax:**

```bash
# Common mistakes:

# ❌ Wrong - Trailing comma
{
  "mcpServers": {
    "server": {},
  }
}

# ❌ Wrong - Single quotes
{
  'mcpServers': {}
}

# ✅ Correct
{
  "mcpServers": {
    "server": {}
  }
}
```

**Validate JSON:**
```bash
# Using Node.js
node -e "console.log(JSON.parse(require('fs').readFileSync('claude_desktop_config.json')))"

# Or online: https://jsonlint.com/
```

## Issue 3: Authentication Errors

**OAuth Flow Issues (Remote MCP):**
- Verify connector name matches documentation (often case-sensitive)
- Check browser popup blockers
- Clear browser cache and retry
- Try incognito/private mode

**API Token Issues (Local MCP):**
```bash
# Verify token format
# Most tokens have specific prefixes (fib_, sk-, etc.)

# Test token manually (example for API-based services)
curl -H "Authorization: Bearer YOUR_TOKEN" https://service.com/api/test

# Common issues:
# - Extra spaces when copying: " token " instead of "token"
# - Expired tokens (regenerate in service settings)
# - Insufficient permissions (check token scope)
```

## Testing & Validation

### Manual Server Testing

```bash
# 1. Test server installation
uv tool list | grep server-name

# 2. Test server help
uv tool run server-name --help

# 3. Test server startup (with debug)
uv tool run server-name \
  --param value \
  --log-level debug
```

### Configuration Validation

See `validation-script.md` for a complete validation script.

**Quick validation:**
```bash
# Verify file exists
ls -la ~/Library/Application\ Support/Claude/claude_desktop_config.json

# Verify JSON syntax
python3 -m json.tool < claude_desktop_config.json
```

### Connection Testing

```bash
# In Claude, ask:
"List all MCP servers currently connected"
"Show available tools from [server-name]"
"Test connection to [server-name]"
```

## Debug Logging

Enable detailed logging for troubleshooting:

```json
{
  "mcpServers": {
    "server-debug": {
      "command": "uv",
      "args": [
        "tool",
        "run",
        "server-name",
        "--log-level", "debug"
      ],
      "env": {
        "MCP_DEBUG": "1",
        "MCP_LOG_LEVEL": "debug"
      }
    }
  }
}
```

**View logs:**
```bash
# macOS
tail -f ~/Library/Logs/Claude/mcp*.log

# Windows
Get-Content $env:APPDATA\Claude\Logs\mcp*.log -Wait

# Linux
tail -f ~/.config/Claude/logs/mcp*.log
```
