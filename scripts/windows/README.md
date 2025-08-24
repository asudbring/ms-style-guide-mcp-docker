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
Verifies that all required software is installed and properly configured.

```powershell
.\scripts\windows\check-prerequisites.ps1
```

### `generate-certs.ps1`
Generates self-signed SSL certificates for HTTPS support.

```powershell
.\scripts\windows\generate-certs.ps1
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

### `test-deployment.ps1`
Tests the deployed services to ensure everything is working correctly.

```powershell
.\scripts\windows\test-deployment.ps1
```

### `quick-start.ps1`
Complete setup script that runs all the above scripts in sequence.

```powershell
.\scripts\windows\quick-start.ps1
```

## Quick Start

To get started quickly:

1. Open PowerShell as Administrator (recommended)
2. Navigate to the project root directory
3. Run the quick start script:

```powershell
.\scripts\windows\quick-start.ps1
```

## Notes

- **Execution Policy**: You may need to adjust PowerShell execution policy:
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```

- **Admin Rights**: Some operations may require administrator privileges, especially for Docker operations and port checking.

- **Firewall**: Windows Firewall may prompt you to allow Docker and related services.

- **Certificate Warnings**: The generated certificates are self-signed, so browsers will show security warnings. This is expected for local development.

## Troubleshooting

### Docker Issues
- Ensure Docker Desktop is running
- Try restarting Docker Desktop if containers fail to start
- Check Windows Subsystem for Linux (WSL) if using WSL 2 backend

### Port Conflicts
- If port 443 is in use, check for IIS or other web servers
- Use `netstat -ano | findstr :443` to identify what's using the port

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
