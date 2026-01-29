# MCP Configuration Patterns

Complete reference for common MCP server configuration patterns.

## Basic Structure

Minimal configuration with a single MCP server:

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

## Advanced Configuration

Configuration with environment variables and debug settings:

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

## Common Patterns

### Pattern 1: Simple Service Connection

For services with minimal configuration requirements:

```json
{
  "mcpServers": {
    "simple-service": {
      "command": "uv",
      "args": [
        "tool",
        "run",
        "service-mcp",
        "--api-key",
        "your-key"
      ]
    }
  }
}
```

**Use when:**
- Service requires only API key authentication
- No custom endpoints or URLs needed
- Default configuration works

### Pattern 2: Self-Hosted Service

For connecting to your own hosted instances:

```json
{
  "mcpServers": {
    "self-hosted": {
      "command": "uv",
      "args": [
        "tool",
        "run",
        "service-mcp",
        "--url",
        "https://your-instance.company.com",
        "--token",
        "token"
      ]
    }
  }
}
```

**Use when:**
- Running your own MCP server instance
- Custom domain or URL required
- Internal company infrastructure

### Pattern 3: Multiple Environments

For maintaining separate production and development configurations:

```json
{
  "mcpServers": {
    "service-prod": {
      "command": "uv",
      "args": ["tool", "run", "service-mcp", "--env", "production"]
    },
    "service-dev": {
      "command": "uv",
      "args": ["tool", "run", "service-mcp", "--env", "development"]
    }
  }
}
```

**Use when:**
- Need to switch between environments
- Testing changes before production
- Maintaining separate data sources

## Debug Configuration

### Debug Logging

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

### Environment Variables

Custom environment variable configuration:

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

**Common environment variables:**
- `API_KEY` / `API_TOKEN` - Authentication credentials
- `MCP_DEBUG` - Enable debug mode
- `MCP_LOG_LEVEL` - Set logging verbosity
- `PATH` - Custom binary paths
- `HOME` - Custom home directory

## Security Best Practices

### 1. Avoid Hardcoded Credentials

**❌ Bad - Hardcoded token:**
```json
{
  "mcpServers": {
    "server": {
      "command": "uv",
      "args": ["tool", "run", "server", "--token", "fib_abc123secret456"]
    }
  }
}
```

**✅ Good - Environment variable:**
```json
{
  "mcpServers": {
    "server": {
      "command": "uv",
      "args": ["tool", "run", "server"],
      "env": {
        "API_TOKEN": "${API_TOKEN}"
      }
    }
  }
}
```

### 2. Use Minimal Permissions

Configure API tokens with minimal required permissions:
- Read-only for query-only use cases
- Write access only when needed
- Scope tokens to specific resources

### 3. Version Control Safety

If storing config in git:

**.gitignore:**
```
claude_desktop_config.json
*.local.json
.env
.env.*
```

**Committed config template:**
```json
{
  "mcpServers": {
    "example": {
      "command": "uv",
      "args": [
        "tool",
        "run",
        "example-mcp",
        "--token",
        "YOUR_TOKEN_HERE"
      ]
    }
  }
}
```

## Troubleshooting Patterns

### Pattern: Missing Required Arguments

**Symptom:** Server exits immediately

**Diagnosis:**
```bash
uv tool run server-name --help
```

**Fix:** Add all required arguments to config

### Pattern: Port Conflicts

**Symptom:** "Address already in use" error

**Diagnosis:**
```bash
# macOS/Linux
lsof -i :8080

# Windows
netstat -ano | findstr :8080
```

**Fix:**
```json
{
  "mcpServers": {
    "server": {
      "command": "uv",
      "args": [
        "tool",
        "run",
        "server",
        "--port", "8081"
      ]
    }
  }
}
```

### Pattern: Python Version Issues

**Symptom:** Server won't start, version errors

**Diagnosis:**
```bash
python3 --version  # Must be 3.10+
```

**Fix:**
```bash
# macOS
brew install python@3.10

# Ubuntu/Debian
sudo apt install python3.10

# Fedora
sudo dnf install python310
```

## Configuration File Locations

### macOS
```
~/Library/Application Support/Claude/claude_desktop_config.json
```

### Windows
```
%APPDATA%\Claude\claude_desktop_config.json
```

### Linux
```
~/.config/Claude/claude_desktop_config.json
```

## Quick Validation

### JSON Syntax Check

```bash
# Using Python
python3 -m json.tool < claude_desktop_config.json

# Using Node.js
node -e "console.log(JSON.parse(require('fs').readFileSync('claude_desktop_config.json')))"
```

### Common JSON Errors

**❌ Trailing comma:**
```json
{
  "mcpServers": {
    "server": {},
  }
}
```

**❌ Single quotes:**
```json
{
  'mcpServers': {}
}
```

**✅ Correct:**
```json
{
  "mcpServers": {
    "server": {}
  }
}
```

## Related References

- See `troubleshooting.md` for detailed issue resolution
- See `platform-specific.md` for OS-specific configuration
- See `validation-script.md` for automated validation
