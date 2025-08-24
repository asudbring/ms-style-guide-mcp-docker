# Windows PowerShell Scripts for MCP Style Guide Docker

This directory contains PowerShell equivalents of the bash scripts for Windows users.

## Prerequisites

Before running these scripts, you'll need:

1. **PowerShell 5.1 or higher** (Windows 10/11 includes this by default)
2. **Docker Desktop for Windows** - https://docs.docker.com/desktop/windows/
3. **OpenSSL** - Usually available with Git for Windows or install separately
4. **Python 3.8+** (optional, for local testing)

## Scripts Overview

### `deploy.ps1` (Primary Script)
Unified deployment script that handles the complete setup process: SSL certificates, container building, deployment, health checks, and VS Code MCP configuration.

```powershell
# Complete deployment with VS Code integration
.\scripts\windows\deploy.ps1

# Deploy without VS Code configuration  
.\scripts\windows\deploy.ps1 -NoVSCode

# Deploy without building containers (use existing)
.\scripts\windows\deploy.ps1 -NoBuild

# Get help and see all options
.\scripts\windows\deploy.ps1 -Help
```

### `install-mcp-config.ps1`
Configures VS Code with the MCP server settings. Automatically called by `deploy.ps1` unless `-NoVSCode` is specified.

```powershell
# Configure VS Code MCP integration
.\scripts\windows\install-mcp-config.ps1

# Force configuration (overwrites existing)
.\scripts\windows\install-mcp-config.ps1 -Force
```

### `test-mcp-installation.ps1`
Tests the deployed services to ensure everything is working correctly and validates MCP server functionality.

```powershell
.\scripts\windows\test-mcp-installation.ps1
```

## Quick Start

We've simplified the deployment to a single unified script:

### Recommended: Unified Deployment
```powershell
# Complete setup with automatic VS Code integration
.\scripts\windows\deploy.ps1
```

This script handles everything:
- ✅ SSL certificate generation
- ✅ Container building  
- ✅ Service deployment
- ✅ Health checks
- ✅ VS Code MCP configuration

### Alternative Options
```powershell
# Deploy without VS Code configuration
.\scripts\windows\deploy.ps1 -NoVSCode

# Deploy without building (use existing containers)
.\scripts\windows\deploy.ps1 -NoBuild

# Manual VS Code setup only
.\scripts\windows\install-mcp-config.ps1
```

## Notes

- **Execution Policy**: You may need to adjust PowerShell execution policy:
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```

- **Admin Rights**: Some operations may require administrator privileges, especially for Docker operations and port checking.

- **Firewall**: Windows Firewall may prompt you to allow Docker and related services.

- **Certificate Warnings**: The generated certificates are self-signed, so browsers will show security warnings. Expect this behavior for local development.

- **HTTP vs HTTPS**: The server supports both HTTP (port 80) and HTTPS (port 443). For VS Code MCP integration, we recommend HTTP to avoid SSL certificate issues.

## VS Code Integration

After deployment, the MCP server will be available at:
- **HTTP**: `http://localhost/mcp` (recommended for VS Code)
- **HTTPS**: `https://localhost/mcp` (for production use)

The `install-mcp-config.ps1` script automatically configures VS Code to use the HTTP endpoint for optimal compatibility.

## Troubleshooting

### Docker Issues
- Ensure Docker Desktop is running
- Try restarting Docker Desktop if containers fail to start
- Check Windows Subsystem for Linux (WSL) if using WSL 2 backend

### Port Conflicts
- If port 443 or 80 is in use, check for IIS or other web servers
- Use `netstat -ano | findstr :443` or `netstat -ano | findstr :80` to identify what's using the ports

### VS Code MCP Connection Issues
- **SSL Certificate Issues**: The deployment automatically configures HTTP endpoint to avoid certificate validation problems
- **Manual Reconfiguration**: Run `.\scripts\windows\install-mcp-config.ps1 -Force` to reset VS Code MCP settings
- **Complete Restart**: Close VS Code completely and restart after configuration changes
- **MCP Extension Required**: Ensure GitHub Copilot Chat with experimental MCP features is enabled

### PowerShell Execution
- If scripts won't run, check execution policy with `Get-ExecutionPolicy`
- Use `Set-ExecutionPolicy RemoteSigned` to allow local scripts

### OpenSSL Issues
- Install Git for Windows which includes OpenSSL
- Or download OpenSSL for Windows separately

## Differences from Linux Scripts

The PowerShell scripts maintain the same functionality as their bash counterparts but with Windows-specific adaptations:

- Uses PowerShell cmdlets instead of shell commands where possible
- Handles Windows file paths with backslashes
- Uses Windows-native methods for checking ports and disk space
- Color output uses PowerShell console colors
- Error handling adapted for PowerShell conventions
- Includes additional VS Code MCP configuration automation
- Supports both HTTP and HTTPS endpoints for compatibility
- Provides batch file option for fully automated setup

## Additional Windows-Specific Features

- **Unified Deployment**: Single `deploy.ps1` script handles complete setup process
- **VS Code Integration**: Automatic MCP configuration for GitHub Copilot Chat
- **HTTP Optimization**: Uses HTTP endpoint by default to avoid SSL certificate issues
- **Smart Certificate Handling**: Generates SSL certificates inline without external dependencies
- **Comprehensive Health Checks**: Validates all services and endpoints before completion
- **Windows-Optimized**: Native PowerShell commands for better Windows compatibility
