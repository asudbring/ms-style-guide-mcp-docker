# Windows PowerShell Scripts for MCP Style Guide Docker

This directory contains PowerShell equivalents of the bash scripts for Windows users.

## Prerequisites

Before running these scripts, ensure you have:

1. **PowerShell 5.1 or higher** (Windows 10/11 includes this by default)
2. **Docker Desktop for Windows** - https://docs.docker.com/desktop/windows/
3. **OpenSSL** - Usually available with Git for Windows or install separately
4. **Python 3.8+** (optional, for local testing)

## Scripts Overview

### `check-prerequisites.ps1`
Verifies that you have installed and properly configured all required software.

```powershell
.\scripts\windows\check-prerequisites.ps1
```

### `generate-certs-fast.ps1`
Generates self-signed SSL certificates for HTTPS support quickly with minimal prompts.

```powershell
.\scripts\windows\generate-certs-fast.ps1
```

### `build.ps1`
Builds the Docker containers for the MCP Style Guide server.

```powershell
.\scripts\windows\build.ps1
```

### `deploy.ps1`
Deploys the services using docker-compose. Use `-Build` parameter to build first.

```powershell
# Deploy with existing containers
.\scripts\windows\deploy.ps1

# Deploy and build containers
.\scripts\windows\deploy.ps1 -Build
```

### `test-mcp-installation.ps1`
Tests the deployed services to ensure everything is working correctly and validates MCP server functionality.

```powershell
.\scripts\windows\test-mcp-installation.ps1
```

### `install-mcp-config.ps1`
Automatically configures VS Code with the MCP server settings for the Microsoft Style Guide server.

```powershell
.\scripts\windows\install-mcp-config.ps1
```

### `full-auto-setup.bat`
Complete automated setup batch file that runs the entire setup process with minimal user interaction.

```batch
.\scripts\windows\full-auto-setup.bat
```

### `quick-start.ps1`
Complete setup script that runs all the above scripts in sequence.

```powershell
.\scripts\windows\quick-start.ps1
```

## Quick Start

To get started quickly, you have several options:

### Option 1: Fully Automated Setup
```batch
.\scripts\windows\full-auto-setup.bat
```

### Option 2: PowerShell Quick Start
```powershell
.\scripts\windows\quick-start.ps1
```

### Option 3: Manual Step-by-Step
1. Open PowerShell as Administrator (recommended)
2. Navigate to the project root directory
3. Run the scripts in sequence:

```powershell
.\scripts\windows\check-prerequisites.ps1
.\scripts\windows\generate-certs-fast.ps1
.\scripts\windows\build.ps1
.\scripts\windows\deploy.ps1
.\scripts\windows\test-mcp-installation.ps1
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

- **HTTP vs HTTPS**: The server supports both HTTP (port 80) and HTTPS (port 443). For VS Code MCP integration, HTTP is recommended to avoid SSL certificate issues.

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
- If VS Code fails to connect to HTTPS endpoint, the HTTP endpoint is automatically configured
- Run `.\scripts\windows\install-mcp-config.ps1` to reconfigure VS Code MCP settings
- Restart VS Code completely after configuration changes

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

- **VS Code Integration**: Automatic MCP configuration for GitHub Copilot
- **Dual Protocol Support**: Both HTTP and HTTPS endpoints available
- **Automated Setup**: Batch file for one-click deployment
- **Windows-Optimized**: Native PowerShell commands for better Windows compatibility
