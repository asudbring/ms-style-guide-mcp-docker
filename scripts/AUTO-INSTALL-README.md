# MCP Server Auto-Installation Scripts

This directory contains automated installation scripts for configuring the Microsoft Style Guide MCP server in VS Code without user intervention.

## Available Scripts

### Windows (PowerShell)

#### `install-mcp-config.ps1`
Automatically installs the MCP server configuration in VS Code.

**Usage:**
```powershell
# Basic installation
.\scripts\windows\install-mcp-config.ps1

# Force overwrite existing configuration
.\scripts\windows\install-mcp-config.ps1 -Force

# Silent installation (no prompts)
.\scripts\windows\install-mcp-config.ps1 -Quiet

# Combine options
.\scripts\windows\install-mcp-config.ps1 -Force -Quiet
```

#### `full-auto-setup.bat`
Complete deployment with automatic VS Code configuration.

**Usage:**
```cmd
.\scripts\windows\full-auto-setup.bat
```

### Linux/macOS (Shell Script)

#### `install-mcp-config.sh`
Automatically installs the MCP server configuration in VS Code.

**Usage:**
```bash
# Basic installation
./scripts/install-mcp-config.sh

# Force overwrite existing configuration
./scripts/install-mcp-config.sh --force

# Silent installation (no prompts)
./scripts/install-mcp-config.sh --quiet

# Show help
./scripts/install-mcp-config.sh --help
```

## Features

### Intelligent Configuration Merging
- Automatically detects existing MCP configurations
- Merges with existing `mcp.json` instead of overwriting
- Creates backups of existing configurations
- Handles missing directories gracefully

### Cross-Platform Support
- **Windows**: Uses PowerShell for robust JSON handling
- **Linux/macOS**: Uses shell script with optional `jq` for JSON processing
- Automatic VS Code installation detection
- Platform-specific configuration paths

### Safety Features
- Backup existing configurations with timestamps
- Non-destructive merging (preserves other MCP servers)
- Force and quiet modes for automation
- Comprehensive error handling

## Integration with Quick-Start Scripts

### Automatic Installation
Set the `AUTO_INSTALL_MCP` environment variable to enable automatic VS Code configuration:

**Windows:**
```powershell
$env:AUTO_INSTALL_MCP = "true"
.\scripts\windows\quick-start.ps1
```

**Linux/macOS:**
```bash
export AUTO_INSTALL_MCP=true
./scripts/quick-start.sh
```

### Manual Installation
Run the installation scripts separately after deployment:

**Windows:**
```powershell
.\scripts\windows\install-mcp-config.ps1
```

**Linux/macOS:**
```bash
./scripts/install-mcp-config.sh
```

## Configuration Details

The scripts install the following enhanced MCP server configuration with Copilot Chat integration:

```json
{
  "servers": {
    "microsoft-style-guide-docker": {
      "type": "http",
      "url": "https://localhost/mcp",
      "transport": "http+sse",
      "headers": {
        "Content-Type": "application/json",
        "User-Agent": "VS-Code-Copilot-Chat"
      },
      "initialization": {
        "endpoint": "https://localhost/mcp/initialize",
        "method": "POST"
      },
      "tls": {
        "rejectUnauthorized": false
      },
      "copilot": {
        "enabled": true,
        "name": "Microsoft Style Guide",
        "description": "Microsoft Style Guide analyzer for content review and improvement suggestions",
        "instructions": "Use this tool to analyze content against Microsoft Style Guide principles. Available analysis types: comprehensive, voice_tone, grammar, terminology, accessibility. Always provide constructive feedback and specific improvement suggestions."
      },
      "tools": {
        "enabled": true,
        "categories": ["writing", "style", "accessibility", "grammar"]
      }
    }
  }
}
```

Additionally, the scripts configure Copilot Chat integration in VS Code settings.json:

```json
{
  "github.copilot.chat.experimental.mcp.enabled": true,
  "github.copilot.chat.experimental.mcp.servers": {
    "microsoft-style-guide-docker": {
      "enabled": true,
      "description": "Microsoft Style Guide analyzer",
      "icon": "$(book)",
      "quickActions": {
        "analyze": {
          "label": "Analyze with Style Guide",
          "command": "analyze_content",
          "description": "Check content against Microsoft Style Guide"
        },
        "improve": {
          "label": "Suggest Improvements",
          "command": "suggest_improvements",
          "description": "Get improvement suggestions"
        },
        "guidelines": {
          "label": "Get Guidelines",
          "command": "get_style_guidelines",
          "description": "View style guidelines"
        }
      }
    }
  }
}
```

## Installation Paths

### VS Code User Settings Locations:
- **Windows**: `%APPDATA%\Code\User\mcp.json`
- **macOS**: `~/Library/Application Support/Code/User/mcp.json`
- **Linux**: `~/.config/Code/User/mcp.json`

## Prerequisites

### Required
- VS Code installed and accessible via PATH or standard locations
- MCP server deployed and running at `https://localhost/`

### Optional
- `jq` (Linux/macOS) - for better JSON processing, falls back gracefully if not available

## Troubleshooting

### VS Code Not Detected
Ensure VS Code is installed and the `code` command is available in your PATH, or install it in standard locations.

### Permission Issues
**Windows**: Run PowerShell as Administrator if you encounter permission errors.
**Linux/macOS**: Ensure you have write permissions to the VS Code user directory.

### Existing Configuration Issues
Use the `--force` flag to overwrite problematic existing configurations.

### MCP Extension Not Working
1. Ensure the MCP extension is installed in VS Code
2. Restart VS Code after configuration installation
3. Verify the MCP server is running: `curl -k https://localhost/health`

### Copilot Chat Integration Issues
1. Check that `github.copilot.chat.experimental.mcp.enabled` is true in settings.json
2. Look for the Microsoft Style Guide in Copilot Chat's @ menu
3. Try using quick actions: type @ in chat and look for "Microsoft Style Guide"
4. Verify tools are available: @microsoft-style-guide-docker analyze "test content"

### Tools Not Showing in VS Code
1. Restart VS Code completely after installation
2. Check that both mcp.json and settings.json were updated correctly
3. Ensure the MCP server is responding: `curl -k -X POST https://localhost/mcp -d '{"jsonrpc":"2.0","method":"tools/list","id":1}' -H "Content-Type: application/json"`

## Examples

### Complete Automated Setup (Windows)
```cmd
# Run the full auto-setup batch file
.\scripts\windows\full-auto-setup.bat
```

### Manual Step-by-Step (Any Platform)
```bash
# 1. Deploy the MCP server
./scripts/quick-start.sh  # or .\scripts\windows\quick-start.ps1

# 2. Install VS Code configuration
./scripts/install-mcp-config.sh  # or .\scripts\windows\install-mcp-config.ps1

# 3. Restart VS Code
# 4. Test: @microsoft-style-guide-docker analyze "Your text here"
```

### Silent Installation for CI/CD
```bash
# Linux/macOS
export AUTO_INSTALL_MCP=true
./scripts/quick-start.sh

# Windows
$env:AUTO_INSTALL_MCP = "true"
.\scripts\windows\quick-start.ps1 -Quiet
```

## Usage Examples

### Using in Copilot Chat
After installation, you can use the Microsoft Style Guide in several ways:

1. **Direct command**: `@microsoft-style-guide-docker analyze "Your content here"`
2. **Quick actions**: Type `@` in Copilot Chat and select "Microsoft Style Guide"
3. **Available tools**:
   - **Analyze Content**: Comprehensive style guide analysis
   - **Suggest Improvements**: Get specific improvement recommendations
   - **Get Guidelines**: Retrieve style guide principles
   - **Search Style Guide**: Search Microsoft's live style guide

### Example Commands
```
@microsoft-style-guide-docker analyze "Let's setup the environment for developers"
@microsoft-style-guide-docker improve "This document will help you to understand the concepts"
@microsoft-style-guide-docker guidelines "accessibility"
```

### Tool Categories
The MCP server provides tools in these categories:
- **Writing**: Content analysis and improvement
- **Style**: Voice, tone, and style compliance
- **Accessibility**: Inclusive language and accessibility guidelines
- **Grammar**: Grammar and terminology checks
