# Microsoft Style Guide MCP Server - Docker Deployment

A production-ready Docker deployment of the Microsoft Style Guide MCP Server. This deployment provides dual HTTP/HTTPS support and cross-platform setup scripts.

## Features

- **Dual Protocol Support**: HTTP (VS Code optimized) and HTTPS (production ready)
- **Cross-Platform**: Linux bash scripts + Windows PowerShell scripts  
- **Auto-Configuration**: Automated VS Code MCP setup
- **Stateless Design**: No Redis dependency, simplified architecture
- **Production Ready**: NGINX reverse proxy with SSL termination

## Architecture

- **NGINX** (Ports 80/443): Reverse proxy with HTTP and HTTPS endpoints
- **FastAPI MCP Server** (Port 8000): Stateless HTTP-based MCP implementation
- **Docker Compose**: Orchestration with health checks and auto-restart

## Quick Start

### Windows Users
```powershell
# Unified deployment script (recommended)
.\scripts\windows\deploy.ps1

# Deploy without VS Code configuration
.\scripts\windows\deploy.ps1 -NoVSCode

# Skip building containers (use existing)
.\scripts\windows\deploy.ps1 -NoBuild

# Manual step-by-step (advanced users)
.\scripts\windows\test-mcp-installation.ps1
.\scripts\windows\install-mcp-config.ps1
```

### Linux/macOS Users
```bash
# Quick start
./scripts/quick-start.sh

# Step by step
./scripts/check-prerequisites.sh
./scripts/generate-certs.sh
./scripts/build.sh
./scripts/deploy-sh.sh
```

## Available Endpoints

After deployment, the MCP server will be available at:

### HTTP Endpoint (Recommended for VS Code)
- **MCP Server**: `http://localhost/mcp`
- **Health Check**: `http://localhost/health`
- **Use Case**: VS Code MCP integration (no certificate issues)

### HTTPS Endpoint (Production Testing)
- **MCP Server**: `https://localhost/mcp` 
- **Health Check**: `https://localhost/health`
- **Use Case**: Production testing with SSL (uses self-signed certificates)

## VS Code Integration

The MCP server provides four tools for GitHub Copilot:
1. **analyze_content** - Analyze text against Microsoft Style Guide principles
2. **get_style_guidelines** - Get specific style guidelines by category
3. **suggest_improvements** - Get improvement suggestions for content
4. **search_style_guide_live** - Search Microsoft Style Guide website

### Automatic Configuration
The deployment script automatically configures VS Code MCP integration:
```powershell
# Automatic VS Code setup included with deployment
.\scripts\windows\deploy.ps1

# Manual VS Code configuration only
.\scripts\windows\install-mcp-config.ps1
```

**Important**: Uses HTTP endpoint to avoid SSL certificate issues with the VS Code MCP client.

### Manual Configuration
Add to your VS Code MCP settings (`%APPDATA%\Code\User\mcp.json` on Windows):
```json
{
  "servers": {
    "microsoft-style-guide-docker": {
      "type": "http",
      "url": "http://localhost/mcp"
    }
  }
}
```

### Testing the Installation

### Verify Services
```bash
# Check container status
docker-compose ps

# Test HTTP endpoint (recommended for VS Code)
curl -X POST http://localhost/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}'

# Test HTTPS endpoint (for production testing)
curl -k -X POST https://localhost/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}'
```

### VS Code Testing
1. Restart VS Code completely
2. Open GitHub Copilot Chat
3. Enable agent mode (@)
4. Ask: "Analyze this text for Microsoft Style Guide compliance: Hello, this is a test."

## Development

### Making Code Changes
1. Edit files in the `src/` directory
2. Rebuild and redeploy:
```bash
# Stop services
docker-compose down

# Rebuild and redeploy
./scripts/build.sh
./scripts/deploy-sh.sh
```

### Viewing Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f mcp-server
docker-compose logs -f mcp-nginx
```

### Development vs Production Configurations
- **Development**: Use `docker-compose.dev.yml` for HTTP/HTTPS dual support
- **Production**: Use `docker-compose.yml` or `docker-compose.prod.yml`

## Configuration Files

### Docker Compose Files
- `docker-compose.yml` - Base configuration
- `docker-compose.prod.yml` - Production overrides
- `docker-compose.dev.yml` - Development with dual protocol support

### NGINX Configurations
- `docker/nginx/nginx.conf` - Production NGINX config
- `docker/nginx/nginx-dev.conf` - Development NGINX config
- `docker/nginx/conf.d/mcp-server.conf` - Production server block
- `docker/nginx/conf.d/mcp-server-dev.conf` - Development server block

## Certificate Management

### Self-Signed Certificates (Development)
The setup scripts automatically generate self-signed certificates for HTTPS support. For VS Code integration, HTTP is recommended to avoid certificate validation issues.

### Production Certificates
1. Replace certificate files in `docker/nginx/ssl/`:
   - `cert.pem` - Your SSL certificate
   - `key.pem` - Your private key

2. Update NGINX configuration for your domain
3. Restart containers:
```bash
docker-compose restart
```

## Troubleshooting

### VS Code Connection Issues
- **SSL Certificate Issues**: The deployment script automatically configures HTTP endpoint (`http://localhost/mcp`) to avoid SSL validation issues
- **Configuration Problems**: Run `.\scripts\windows\install-mcp-config.ps1` to reconfigure VS Code MCP settings
- **Restart Required**: Completely close and restart VS Code after configuration changes
- **MCP Extension**: Ensure GitHub Copilot Chat experimental MCP features are enabled

### Container Issues
```bash
# Check container status
docker-compose ps

# View container logs
docker-compose logs mcp-server
docker-compose logs mcp-nginx

# Restart services
docker-compose restart
```

### Port Conflicts
```bash
# Check what's using ports 80/443
netstat -tlnp | grep :80
netstat -tlnp | grep :443

# Windows equivalent
netstat -ano | findstr :80
netstat -ano | findstr :443
```

### Network Connectivity
```bash
# Test health endpoint
curl http://localhost/health

# Test MCP endpoint
curl -X POST http://localhost/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2024-11-05", "capabilities": {"roots": {"listChanged": true}}, "clientInfo": {"name": "test", "version": "1.0"}}}'
```

## Project Structure

```
ms-style-guide-mcp-docker/
├── src/
│   ├── mcp_http_server.py       # FastAPI MCP server (stateless)
│   ├── style_analyzer.py        # Microsoft Style Guide analyzer
│   ├── mcp_config.py           # Configuration management
│   └── requirements.txt        # Python dependencies
├── docker/
│   ├── dockerfile.mcp          # MCP server container
│   ├── dockerfile.nginx        # NGINX container
│   └── nginx/
│       ├── nginx.conf          # Production NGINX config
│       ├── nginx-dev.conf      # Development NGINX config
│       ├── conf.d/
│       │   ├── mcp-server.conf     # Production server config
│       │   └── mcp-server-dev.conf # Development server config
│       └── ssl/                # SSL certificates directory
│           └── .gitkeep        # Placeholder file
├── scripts/
│   ├── Linux/macOS bash scripts:
│   ├── build.sh               # Build containers
│   ├── check-prerequisites.sh # Verify requirements
│   ├── deploy-sh.sh          # Deploy services
│   ├── generate-certs.sh     # Generate SSL certificates
│   ├── install-mcp-config.sh # Configure VS Code
│   ├── quick-start.sh        # Complete setup
│   └── windows/              # Windows PowerShell scripts
│       ├── deploy.ps1                  # Unified deployment script
│       ├── install-mcp-config.ps1      # VS Code MCP configuration
│       ├── test-mcp-installation.ps1   # Installation testing
│       └── README.md                   # Windows-specific documentation
├── .vscode/
│   └── mcp-config.json        # Sample VS Code MCP configuration
├── docker-compose.yml         # Base configuration
├── docker-compose.prod.yml    # Production overrides
├── docker-compose.dev.yml     # Development configuration
├── .gitignore                 # Git ignore rules
├── .dockerignore             # Docker ignore rules
├── .env.example              # Environment variables template
└── README.md                 # This file
```

## Environment Variables

The server supports these environment variables (see `.env.example`):

```env
# Server Configuration
LOG_LEVEL=INFO
PYTHONUNBUFFERED=1

# NGINX Configuration  
NGINX_PORT=443
NGINX_HTTP_PORT=80

# Development Settings
DEVELOPMENT_MODE=false
```

## Security Considerations

- **No Authentication**: This deployment has no built-in authentication as designed for local development
- **HTTPS Support**: Production-ready SSL/TLS configuration with modern cipher suites
- **Non-root Containers**: Both containers run with non-privileged users
- **Network Isolation**: Containers communicate over isolated Docker network
- **Health Checks**: Automated health monitoring for service reliability

## Performance

- **Stateless Design**: No session state, enabling horizontal scaling
- **NGINX Optimization**: Configured for optimal performance with gzip compression
- **Connection Pooling**: Efficient connection management
- **Health Checks**: Automatic service recovery
- **Resource Limits**: Configured resource constraints for production deployment

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with both HTTP and HTTPS endpoints
5. Verify cross-platform compatibility (test Windows scripts if modifying them)
6. Submit a pull request

## Support

For issues and questions:
1. Check the troubleshooting section above
2. Review container logs: `docker-compose logs`
3. Verify service health: `curl http://localhost/health`
4. Test MCP tools directly via curl commands shown in testing section

## License

This project is licensed under the MIT License - see the LICENSE file for details.