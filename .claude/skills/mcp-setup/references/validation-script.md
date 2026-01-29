# MCP Configuration Validation Script

**Purpose:** Automated validation of Claude Desktop MCP configuration file.

## Python Validation Script

```python
#!/usr/bin/env python3
"""
MCP Configuration Validator
Validates Claude Desktop MCP server configuration files.
"""

import json
import sys
from pathlib import Path
from typing import Dict, Any, List, Tuple

class ConfigValidator:
    """Validates MCP server configuration."""

    REQUIRED_SERVER_KEYS = ['command']
    COMMON_ISSUES = {
        'trailing_comma': 'JSON contains trailing comma',
        'single_quotes': "JSON uses single quotes instead of double quotes",
        'missing_command': 'Server configuration missing required "command" field',
        'args_not_list': '"args" field must be a list',
    }

    def __init__(self, config_path: Path):
        self.config_path = config_path
        self.errors: List[str] = []
        self.warnings: List[str] = []

    def validate(self) -> bool:
        """Run all validation checks."""
        try:
            # Check file exists
            if not self.config_path.exists():
                self.errors.append(f"Config file not found: {self.config_path}")
                return False

            # Read and parse JSON
            with open(self.config_path, 'r') as f:
                try:
                    config = json.load(f)
                except json.JSONDecodeError as e:
                    self.errors.append(f"Invalid JSON: {e}")
                    self._suggest_json_fix(e)
                    return False

            # Validate structure
            self._validate_structure(config)

            # Validate each server
            if 'mcpServers' in config:
                self._validate_servers(config['mcpServers'])

            return len(self.errors) == 0

        except Exception as e:
            self.errors.append(f"Unexpected error: {e}")
            return False

    def _validate_structure(self, config: Dict[str, Any]):
        """Validate top-level config structure."""
        if not isinstance(config, dict):
            self.errors.append("Config must be a JSON object")
            return

        if 'mcpServers' not in config:
            self.warnings.append("Missing 'mcpServers' key - no servers configured")
            return

        if not isinstance(config['mcpServers'], dict):
            self.errors.append("'mcpServers' must be an object")

    def _validate_servers(self, servers: Dict[str, Any]):
        """Validate each MCP server configuration."""
        for server_name, server_config in servers.items():
            self._validate_server(server_name, server_config)

    def _validate_server(self, name: str, config: Dict[str, Any]):
        """Validate individual server configuration."""
        prefix = f"Server '{name}'"

        # Check it's a dict
        if not isinstance(config, dict):
            self.errors.append(f"{prefix}: Configuration must be an object")
            return

        # Check required fields
        for required in self.REQUIRED_SERVER_KEYS:
            if required not in config:
                self.errors.append(f"{prefix}: Missing required field '{required}'")

        # Validate command
        if 'command' in config and not isinstance(config['command'], str):
            self.errors.append(f"{prefix}: 'command' must be a string")

        # Validate args
        if 'args' in config:
            if not isinstance(config['args'], list):
                self.errors.append(f"{prefix}: 'args' must be a list")
            elif len(config['args']) == 0:
                self.warnings.append(f"{prefix}: 'args' is empty")

        # Validate env
        if 'env' in config and not isinstance(config['env'], dict):
            self.errors.append(f"{prefix}: 'env' must be an object")

        # Check for common mistakes
        self._check_common_mistakes(name, config)

    def _check_common_mistakes(self, name: str, config: Dict[str, Any]):
        """Check for common configuration mistakes."""
        prefix = f"Server '{name}'"

        # Check for hardcoded tokens in config (security issue)
        args = config.get('args', [])
        for i, arg in enumerate(args):
            if isinstance(arg, str):
                # Check for token-like patterns
                if any(keyword in arg.lower() for keyword in ['token', 'key', 'secret']):
                    if i + 1 < len(args) and len(str(args[i + 1])) > 20:
                        self.warnings.append(
                            f"{prefix}: Possible hardcoded credential in args. "
                            "Consider using environment variables."
                        )
                        break

    def _suggest_json_fix(self, error: json.JSONDecodeError):
        """Suggest fixes for common JSON errors."""
        error_msg = str(error)

        if 'Expecting property name' in error_msg:
            self.warnings.append(
                "Hint: Check for trailing commas or missing quotes around object keys"
            )
        elif 'Expecting value' in error_msg:
            self.warnings.append(
                "Hint: Check for missing values or trailing commas in arrays/objects"
            )

    def print_results(self):
        """Print validation results."""
        if self.errors:
            print("❌ ERRORS FOUND:")
            for error in self.errors:
                print(f"  • {error}")
            print()

        if self.warnings:
            print("⚠️  WARNINGS:")
            for warning in self.warnings:
                print(f"  • {warning}")
            print()

        if not self.errors and not self.warnings:
            print("✅ Configuration is valid!")
        elif not self.errors:
            print("✅ Configuration is valid (with warnings)")
        else:
            print("❌ Configuration has errors that must be fixed")


def get_config_path() -> Path:
    """Get Claude Desktop config path for current platform."""
    import platform
    system = platform.system()

    if system == 'Darwin':  # macOS
        return Path.home() / 'Library' / 'Application Support' / 'Claude' / 'claude_desktop_config.json'
    elif system == 'Windows':
        appdata = Path(os.environ.get('APPDATA', ''))
        return appdata / 'Claude' / 'claude_desktop_config.json'
    else:  # Linux
        return Path.home() / '.config' / 'Claude' / 'claude_desktop_config.json'


def main():
    """Main entry point."""
    import argparse

    parser = argparse.ArgumentParser(description='Validate Claude Desktop MCP configuration')
    parser.add_argument(
        'config_path',
        nargs='?',
        type=Path,
        help='Path to config file (default: auto-detect for platform)'
    )

    args = parser.parse_args()

    # Use provided path or auto-detect
    config_path = args.config_path or get_config_path()

    print(f"Validating: {config_path}\n")

    # Run validation
    validator = ConfigValidator(config_path)
    is_valid = validator.validate()
    validator.print_results()

    # Exit with appropriate code
    sys.exit(0 if is_valid else 1)


if __name__ == '__main__':
    main()
```

## Usage

```bash
# Auto-detect config location
python3 validate_mcp_config.py

# Specify custom path
python3 validate_mcp_config.py ~/custom/path/config.json

# Use in CI/CD
python3 validate_mcp_config.py && echo "Config valid" || echo "Config invalid"
```

## Example Output

### Valid Configuration

```
Validating: /Users/user/Library/Application Support/Claude/claude_desktop_config.json

✅ Configuration is valid!
```

### Configuration with Errors

```
Validating: /Users/user/Library/Application Support/Claude/claude_desktop_config.json

❌ ERRORS FOUND:
  • Server 'fibery': Missing required field 'command'
  • Server 'custom': 'args' must be a list

⚠️  WARNINGS:
  • Hint: Check for trailing commas or missing quotes around object keys

❌ Configuration has errors that must be fixed
```

### Configuration with Warnings Only

```
Validating: /Users/user/Library/Application Support/Claude/claude_desktop_config.json

⚠️  WARNINGS:
  • Server 'test-server': 'args' is empty
  • Server 'api-service': Possible hardcoded credential in args. Consider using environment variables.

✅ Configuration is valid (with warnings)
```

## Quick Checks Without Script

### Using Node.js

```bash
# Validate JSON syntax
node -e "console.log(JSON.parse(require('fs').readFileSync('claude_desktop_config.json', 'utf8')))"

# Expected: Parsed JSON output
# If error: Fix syntax issue mentioned in error message
```

### Using Python

```bash
# Quick syntax check
python3 -c "import json; json.load(open('claude_desktop_config.json'))" && echo "Valid JSON" || echo "Invalid JSON"

# Pretty-print
python3 -m json.tool < claude_desktop_config.json
```

### Online Validators

Copy config content to:
- https://jsonlint.com/
- https://jsonformatter.org/

**Note:** Remove sensitive tokens before using online validators!

## Common Issues Detected

| Issue | Detection | Fix |
|-------|-----------|-----|
| Trailing comma | JSON parse error | Remove last comma in object/array |
| Single quotes | Parse fails | Replace `'` with `"` |
| Missing quotes | Invalid key | Add quotes: `"key": value` |
| Wrong type | Type validation | Fix type (string, list, object) |
| Hardcoded tokens | Pattern matching | Use environment variables |
| Empty args | Warning | Verify intentional |

## Integration with CI/CD

### GitHub Actions

```yaml
name: Validate MCP Config
on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Validate config
        run: python3 .claude/skills/mcp-setup/references/validate_mcp_config.py config/claude_desktop_config.json
```

### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

if [ -f "claude_desktop_config.json" ]; then
    python3 validate_mcp_config.py claude_desktop_config.json
    if [ $? -ne 0 ]; then
        echo "MCP config validation failed. Fix errors before committing."
        exit 1
    fi
fi
```

## Related References

- See `troubleshooting.md` for detailed issue resolution
- See `../SKILL.md` for setup instructions
- See `examples.md` for configuration templates
