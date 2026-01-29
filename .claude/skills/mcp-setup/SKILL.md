---
name: mcp-setup
description: Install and configure MCP (Model Context Protocol) servers for Claude Code. Handles both Remote MCP (OAuth-based, easy setup) and Local MCP (development-focused, requires manual configuration). Use this when setting up any MCP server integration.
allowed-tools: "Read,Write,Edit,Bash,Grep"
---

# MCP Setup Skill

**Version:** 1.0
**Last Updated:** 2025-11-11

## What This Skill Does

Guides you through installing and configuring MCP (Model Context Protocol) servers for Claude Code. MCP servers enable Claude to interact with external services and data sources through a standardized protocol.

## When to Use This Skill

- Setting up first-time MCP server integration
- Adding new MCP servers to existing configuration
- Troubleshooting MCP connection issues
- Migrating from Remote to Local MCP (or vice versa)
- Validating MCP server configuration

## Prerequisites

**For Remote MCP (Recommended):**
- Service account with OAuth support
- Browser for authentication flow

**For Local MCP:**
- Python 3.10+ installed
- `uv` package installer: `pip install uv`
- API token from the service

## Quick Start

### Method 1: Remote MCP (Easiest)

Remote MCP uses OAuth 2.0 authentication - no API tokens needed.

**Steps:**

1. **Navigate to Settings in Claude**
   - Claude Desktop: `Settings → Connectors → Add custom connector`
   - Claude Web: Similar path in settings menu

2. **Fill in connector details:**
   - **Name:** Service-specific (check service documentation)
   - **URL:** Service-provided MCP endpoint

3. **Authenticate via OAuth**
   - Claude opens OAuth flow
   - Log in to your service account
   - Grant permissions
   - Done!

4. **Verify connection:**
   ```
   Ask Claude: "What data can you access from [service]?"
   ```

### Method 2: Local MCP (Advanced)

Local MCP requires manual configuration but offers more control.

**Step 1: Install MCP Server**

```bash
# Generic installation pattern
uv tool install [mcp-server-package-name]

# Example for Fibery
uv tool install fibery-mcp-server

# Verify installation
uv tool list
```

**Step 2: Get API Token**

1. Log in to service
2. Navigate to Settings → API Keys (path varies by service)
3. Generate new API key
4. Copy token (save it - may not be shown again)

**Step 3: Configure Claude Desktop**

1. **Open config file:**
   - **macOS:** `~/Library/Application Support/Claude/claude_desktop_config.json`
   - **Windows:** `%APPDATA%\Claude\claude_desktop_config.json`
   - **Linux:** `~/.config/Claude/claude_desktop_config.json`

2. **Add server configuration:**

```json
{
  "mcpServers": {
    "server-name": {
      "command": "uv",
      "args": [
        "tool",
        "run",
        "server-package-name",
        "--host",
        "your-domain.service.com",
        "--api-token",
        "your-api-token-here"
      ]
    }
  }
}
```

3. **Replace placeholders:**
   - `server-name` → Descriptive identifier (e.g., "fibery-mcp")
   - `server-package-name` → PyPI package name
   - Service-specific parameters (check documentation)

4. **Save and restart Claude Desktop**

**Step 4: Verify Connection**

```bash
# Ask Claude to test the connection
"List all available tools from [service] MCP server"
"Test connection to [service]"
```

## Configuration File Structure

### Basic Structure

```json
{
  "mcpServers": {
    "server-1": {
      "command": "uv",
      "args": ["tool", "run", "package-1", "--param", "value"]
    },
    "server-2": {
      "command": "uv",
      "args": ["tool", "run", "package-2", "--param", "value"]
    }
  }
}
```

### Advanced Configuration

```json
{
  "mcpServers": {
    "advanced-server": {
      "command": "uv",
      "args": [
        "tool",
        "run",
        "server-package",
        "--host", "domain.com",
        "--api-token", "token",
        "--log-level", "debug"
      ],
      "env": {
        "MCP_DEBUG": "1",
        "MCP_LOG_LEVEL": "debug",
        "CUSTOM_VAR": "value"
      }
    }
  }
}
```

## Common Configuration Patterns

**For detailed configuration patterns** including simple services, self-hosted instances, multiple environments, security best practices, and troubleshooting patterns, see `references/configuration-patterns.md`.

## Troubleshooting Guide

**For detailed troubleshooting guidance** including server transport errors, configuration file validation, authentication issues, and platform-specific solutions, see `references/troubleshooting.md` and `references/platform-specific.md`.

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

See `references/validation-script.md` for a complete validation script.

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

## Pre-Flight Checklist

Before starting MCP setup:

**Basic Requirements:**
- [ ] Service account created
- [ ] For Local MCP: Python 3.10+ installed (`python3 --version`)
- [ ] For Local MCP: `uv` installed (`uv --version`)
- [ ] Claude Desktop installed and updated

**Configuration Readiness:**
- [ ] API token generated (for Local MCP)
- [ ] Service URL/domain known
- [ ] Required parameters documented
- [ ] Config file location identified

**Post-Setup Verification:**
- [ ] Claude Desktop restarted
- [ ] Connection test passed
- [ ] Tools available in Claude
- [ ] No errors in logs

## Common Mistakes to Avoid

1. **❌ Wrong config file location**
   - Always verify exact path for your OS
   - Create directory if it doesn't exist

2. **❌ Missing required arguments**
   - Check service documentation for all required params
   - Test manually first: `uv tool run server-name --help`

3. **❌ Forgetting to restart Claude**
   - Config changes require full restart
   - Not just closing window - quit application

4. **❌ Using wrong token type**
   - API tokens ≠ OAuth tokens
   - Check which auth method your service uses

5. **❌ Copying tokens with extra spaces**
   - Trim whitespace: `token` not ` token `
   - Verify in text editor before pasting

## Advanced Features

### Debug Logging

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

### Environment Variables

```json
{
  "mcpServers": {
    "server-with-env": {
      "command": "uv",
      "args": ["tool", "run", "server"],
      "env": {
        "API_KEY": "value",
        "CUSTOM_VAR": "value",
        "PATH": "/custom/path:${PATH}"
      }
    }
  }
}
```

## When to Choose Remote vs Local

### Choose Remote MCP When:
- ✅ Quick setup needed
- ✅ Non-technical users
- ✅ Service supports OAuth
- ✅ No local development requirements
- ✅ Don't want to manage tokens

### Choose Local MCP When:
- ✅ Development/testing environment
- ✅ Strict data residency requirements
- ✅ Need debug access
- ✅ Service doesn't support OAuth
- ✅ Want full control over configuration

## Best Practices

1. **Start simple** - Get basic connection working first
2. **Test incrementally** - Add one server at a time
3. **Document tokens** - Store in password manager, not config comments
4. **Use version control** - Track config changes (but gitignore tokens!)
5. **Enable logging** - Easier to debug when things break
6. **Validate JSON** - Always validate before saving
7. **Test manually** - Run server directly before adding to Claude

## Next Steps After Setup

1. **Explore capabilities:**
   ```
   "What tools are available from [server]?"
   "Show me example commands for [server]"
   ```

2. **Test basic operations:**
   ```
   "List all [resources] from [server]"
   "Create a test [item] in [server]"
   ```

3. **Read service documentation:**
   - Understand available tools
   - Learn query syntax
   - Review rate limits

4. **Create workflows:**
   - Document common patterns
   - Build Claude Code skills
   - Share with team

## Support Resources

**MCP Protocol:**
- Official Spec: https://modelcontextprotocol.io/
- Community: https://github.com/modelcontextprotocol

**Claude Code:**
- Documentation: https://docs.claude.com/
- GitHub: https://github.com/anthropics/claude-code

**Service-Specific:**
- Check service documentation for MCP guides
- Community forums often have setup examples
- GitHub repos may have troubleshooting guides

## Related Skills

- `fibery-integration` - Specific setup for Fibery MCP
- `project-coordinator` - Multi-project task management via MCP
- `content-strategist` - Content workflows using MCP data

## Revision History

- **1.0** (2025-11-11) - Initial skill creation extracted from Fibery guide
