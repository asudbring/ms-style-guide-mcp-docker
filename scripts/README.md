# Shell Scripts for MCP Style Guide Docker

This directory contains cross-platform shell scripts for deploying the Microsoft Style Guide MCP server on Linux, macOS, and Windows (Git Bash/WSL).

## Prerequisites

Before running these scripts, you'll need:

1. **Bash shell** (available on Linux, macOS, Git Bash for Windows)
   - **macOS Note**: These scripts work perfectly on macOS even though zsh is the default shell since macOS Catalina. The scripts use `#!/bin/bash` shebang lines to ensure they run with bash regardless of your default shell.
2. **Docker** (20.10.0+) - https://docs.docker.com/get-docker/
3. **Docker Compose** (2.0.0+) - https://docs.docker.com/compose/install/
4. **OpenSSL** - Usually pre-installed on most Unix-like systems
5. **curl** - For health checks and testing

## Scripts Overview

### `deploy.sh` (Primary Script)
Complete deployment script that handles the entire setup process: SSL certificate generation, container building, deployment, health checks, and VS Code MCP configuration.

```bash
# Complete deployment with VS Code integration
./scripts/deploy.sh

# Deploy without VS Code configuration  
./scripts/deploy.sh --no-vscode

# Deploy without building containers (use existing)
./scripts/deploy.sh --no-build

# Get help and see all options
./scripts/deploy.sh --help
```

### `check-prerequisites.sh`
Validates system requirements and checks if all necessary tools are installed before deployment.

```bash
# Check if system meets requirements
./scripts/check-prerequisites.sh
```

### `install-mcp-config.sh`
Configures VS Code with the MCP server settings across different operating systems. Automatically called by `deploy.sh` unless `--no-vscode` is specified.

```bash
# Configure VS Code MCP integration
./scripts/install-mcp-config.sh

# Force configuration (overwrites existing)
./scripts/install-mcp-config.sh --force

# Run in quiet mode
./scripts/install-mcp-config.sh --quiet
```

### `test-vscode-integration.sh`
Tests VS Code MCP integration and validates the deployment.

```bash
# Test MCP integration
./scripts/test-vscode-integration.sh
```

## Quick Start

We recommend running the prerequisite check first, then the unified deployment:

### Step 1: Check Prerequisites
```bash
# Verify system requirements
./scripts/check-prerequisites.sh
```

### Step 2: Complete Deployment
```bash
# Complete setup with automatic VS Code integration
./scripts/deploy.sh
```

This script handles everything:
- ✅ SSL certificate generation (inline, no external scripts)
- ✅ Container building  
- ✅ Service deployment
- ✅ Comprehensive health checks
- ✅ Cross-platform VS Code MCP configuration

### Alternative Options
```bash
# Deploy without VS Code configuration
./scripts/deploy.sh --no-vscode

# Deploy without building (use existing containers)
./scripts/deploy.sh --no-build

# Manual VS Code setup only
./scripts/install-mcp-config.sh --force
```

## Cross-Platform Support

The shell scripts automatically detect and adapt to different operating systems:

### **Linux**
- **OS Detection**: `Linux*`
- **VS Code Path**: `~/.config/Code/User`
- **Package Requirements**: Standard Linux tools (curl, openssl, docker)

### **macOS**
- **OS Detection**: `Darwin*`
- **VS Code Path**: `~/Library/Application Support/Code/User`
- **Package Requirements**: Xcode command line tools, Docker Desktop
- **Shell Compatibility**: Works with both bash and zsh (scripts use `#!/bin/bash` shebang)

### **Windows (Git Bash/WSL)**
- **OS Detection**: `MINGW64_NT-*`, `MSYS_NT-*`, `CYGWIN_NT-*`
- **VS Code Path**: `~/AppData/Roaming/Code/User`
- **Package Requirements**: Git for Windows, Docker Desktop

## Detailed Script Features

### `deploy.sh` Features
- **Integrated SSL Generation**: No external certificate scripts needed
- **Smart Path Handling**: Works with Git Bash path translation on Windows
- **Error Handling**: Graceful failure recovery with informative messages
- **Health Validation**: Tests HTTP, HTTPS, and MCP endpoints
- **Progress Tracking**: Clear step-by-step progress indicators
- **Colored Output**: Easy-to-read status messages

### `install-mcp-config.sh` Features
- **Cross-Platform Detection**: Automatically handles Linux/macOS/Windows paths
- **Configuration Backup**: Creates timestamped backups before changes
- **Merge Capability**: Preserves existing MCP configurations when possible
- **HTTP Optimization**: Uses HTTP endpoint to avoid SSL certificate issues
- **VS Code Integration**: Automatic Copilot Chat configuration

### `check-prerequisites.sh` Features
- **Docker Validation**: Checks Docker daemon, version compatibility
- **Port Availability**: Verifies required ports (443, 80) are free
- **Tool Detection**: Validates OpenSSL, curl, and other dependencies
- **VS Code Detection**: Optional check for VS Code installation
- **Clean Output**: No false errors for optional components

## Usage Examples

### Complete Fresh Setup
```bash
# 1. Check system readiness
./scripts/check-prerequisites.sh

# 2. Deploy everything
./scripts/deploy.sh

# 3. Test the installation (optional)
./scripts/test-vscode-integration.sh
```

### Development Workflow
```bash
# Quick rebuild without VS Code reconfiguration
./scripts/deploy.sh --no-vscode

# Reconfigure VS Code only
./scripts/install-mcp-config.sh --force

# Clean deployment with new containers
docker-compose down && ./scripts/deploy.sh
```

### Troubleshooting Workflow
```bash
# Check what's wrong
./scripts/check-prerequisites.sh

# Test endpoints manually
curl http://localhost/health
curl -X POST http://localhost/mcp -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'

# Reconfigure VS Code
./scripts/install-mcp-config.sh --force
```

## Notes and Best Practices

### File Permissions
```bash
# Make scripts executable (if needed)
chmod +x scripts/*.sh
```

### Git Bash on Windows
- Scripts automatically handle Windows path translation
- Uses `MSYS_NO_PATHCONV=1` for OpenSSL certificate generation
- Compatible with standard Git for Windows installation

### Certificate Handling
- The system automatically generates self-signed certificates
- Browsers will show security warnings (expected for local development)
- MCP client uses HTTP endpoint to avoid certificate validation issues

### Docker Requirements
- Docker daemon must be running before deployment
- User must have permission to run Docker commands
- Sufficient disk space required for container images

## VS Code Integration

After deployment, the MCP server will be available at:
- **HTTP**: `http://localhost/mcp` (recommended for VS Code)
- **HTTPS**: `https://localhost/mcp` (for production use)

The `install-mcp-config.sh` script automatically:
1. Detects your operating system and VS Code installation
2. Creates appropriate configuration paths
3. Backs up existing configurations
4. Configures HTTP endpoint for optimal compatibility
5. Sets up Copilot Chat integration (where supported)

## Troubleshooting

### Common Issues

#### Permission Errors
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Check Docker permissions
sudo usermod -aG docker $USER
# (sign out/sign in required)
```

#### Docker Issues
```bash
# Check Docker status
docker info

# Restart Docker (Linux/macOS)
sudo systemctl restart docker

# Clean Docker state
docker system prune -f
```

#### Path Issues (Git Bash on Windows)
- Scripts automatically handle Windows/Unix path translation
- If issues persist, try running from project root directory
- Ensure Git for Windows is properly installed

#### VS Code Configuration Issues
```bash
# Force reconfiguration
./scripts/install-mcp-config.sh --force

# Check VS Code paths
ls -la ~/.config/Code/User/        # Linux
ls -la ~/Library/Application\ Support/Code/User/  # macOS
ls -la ~/AppData/Roaming/Code/User/  # Windows (Git Bash)
```

#### SSL Certificate Issues
- OpenSSL automatically generates certificates
- Git Bash users: ensure Git for Windows includes OpenSSL
- Manual certificate check: `openssl version`

#### Port Conflicts
```bash
# Check what's using ports
lsof -i :443 -i :80    # Linux/macOS
netstat -ano | grep :443  # Git Bash/Windows
```

## Differences from PowerShell Scripts

The shell scripts provide equivalent functionality to the PowerShell versions with these adaptations:

- **Cross-Platform**: Works on Linux, macOS, and Windows (Git Bash)
- **POSIX Compliance**: Uses standard Unix/Linux commands and conventions
- **Path Handling**: Automatically adapts to different file system conventions
- **Package Detection**: Uses standard Unix tools for system validation
- **Error Handling**: Bash-style error handling and exit codes
- **Color Output**: ANSI color codes for terminal output

## Advanced Usage

### Environment Variables
```bash
# Skip interactive prompts
export MCP_QUIET=1

# Custom VS Code path
export VSCODE_USER_DIR="/custom/path/to/vscode/user"

# Custom Docker Compose files
export COMPOSE_FILE="docker-compose.yml:docker-compose.custom.yml"
```

### Integration with CI/CD
```bash
# Non-interactive deployment
./scripts/deploy.sh --no-vscode --quiet

# Health check for monitoring
./scripts/test-vscode-integration.sh && echo "Service healthy"
```

### Development Features
- **Hot Reload**: Modify source files and restart containers
- **Debug Mode**: Enable verbose logging in containers
- **Custom Configurations**: Override default settings via environment variables

The shell scripts provide a robust, cross-platform deployment solution that maintains feature parity with the PowerShell equivalents while offering the flexibility and portability of standard Unix tools.
