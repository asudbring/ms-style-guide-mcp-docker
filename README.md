# MCP Style Guide Server - Docker Deployment

Production-ready Docker deployment of the Microsoft Style Guide MCP Server with HTTPS support, designed for easy Azure migration.

## Architecture

- **NGINX** (Port 443): Reverse proxy with HTTPS termination
- **FastAPI MCP Server** (Port 8000): HTTP-based MCP implementation
- **Redis**: Session management and caching
- **Docker Compose**: Orchestration with health checks

## Quick Start

### 1. Project Setup

```bash
# Create project structure
mkdir mcp-style-guide-docker
cd mcp-style-guide-docker

# Create directory structure
mkdir -p src docker/nginx/ssl docker/nginx/conf.d scripts logs/mcp logs/nginx .vscode

# Copy all artifact files to their respective locations
# Make scripts executable
chmod +x scripts/*.sh
```

### 2. Generate Certificates

```bash
./scripts/generate-certs.sh
```

### 3. Build and Deploy

```bash
# Build containers
./scripts/build.sh

# Deploy services
./scripts/deploy.sh
```

### 4. Configure VS Code

Copy the MCP configuration to your VS Code user settings:
- Windows: `%APPDATA%\Code\User\mcp.json`
- macOS: `~/Library/Application Support/Code/User/mcp.json`
- Linux: `~/.config/Code/User/mcp.json`

```json
{
  "servers": {
    "microsoft-style-guide-docker": {
      "type": "http",
      "url": "https://localhost/mcp",
      "transport": "http+sse",
      "headers": {
        "Content-Type": "application/json"
      },
      "initialization": {
        "endpoint": "https://localhost/mcp/initialize",
        "method": "POST"
      },
      "tls": {
        "rejectUnauthorized": false
      }
    }
  }
}
```

## Testing

### Verify Services

```bash
# Check all services are running
docker-compose ps

# Test HTTPS endpoint
curl -k https://localhost/health

# Test MCP initialization
curl -k -X POST https://localhost/mcp/initialize \
  -H "Content-Type: application/json" \
  -H "X-MCP-Client-Name: test-client"
```

### VS Code Integration

1. Open VS Code
2. Ensure MCP extension is installed
3. Look for "microsoft-style-guide-docker" in MCP servers list
4. Test with: `@microsoft-style-guide-docker analyze "Your text here"`

## Development Workflow

Since this is configured for production-like development:

### Making Code Changes

1. Edit files in `src/` directory
2. Rebuild and redeploy:
```bash
# Stop services
docker-compose down

# Rebuild
./scripts/build.sh

# Deploy
./scripts/deploy.sh
```

### Viewing Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f mcp-server
docker-compose logs -f nginx

# Access logs
docker exec mcp-nginx tail -f /var/log/nginx/mcp-access.log
```

## Certificate Management

### Using Commercial Certificates

1. Prepare your certificate files:
   - Certificate: `your-domain.crt`
   - Private key: `your-domain.key`
   - Certificate chain: `your-domain-chain.crt`

2. Combine certificates:
```bash
cat your-domain.crt your-domain-chain.crt > combined-cert.pem
```

3. Replace certificates:
```bash
# Backup existing
mv docker/nginx/ssl/cert.pem docker/nginx/ssl/cert.pem.backup
mv docker/nginx/ssl/key.pem docker/nginx/ssl/key.pem.backup

# Copy new certificates
cp combined-cert.pem docker/nginx/ssl/cert.pem
cp your-domain.key docker/nginx/ssl/key.pem

# Set permissions
chmod 644 docker/nginx/ssl/cert.pem
chmod 600 docker/nginx/ssl/key.pem
```

4. Update NGINX configuration (if using custom domain):
```nginx
server_name your-domain.com;
```

5. Update VS Code configuration:
```json
"url": "https://your-domain.com/mcp",
"tls": {
  "rejectUnauthorized": true
}
```

6. Restart NGINX:
```bash
docker-compose restart nginx
```

## Azure Migration

This setup is designed for minimal changes when migrating to Azure:

### 1. Build for Azure Container Registry

```bash
# Tag images
docker tag mcp-style-guide-docker_mcp-server:latest yourregistry.azurecr.io/mcp-server:latest
docker tag mcp-style-guide-docker_nginx:latest yourregistry.azurecr.io/mcp-nginx:latest

# Push to registry
docker push yourregistry.azurecr.io/mcp-server:latest
docker push yourregistry.azurecr.io/mcp-nginx:latest
```

### 2. Update Environment Variables

Create Azure-specific `.env`:
```env
REDIS_URL=your-azure-redis.redis.cache.windows.net:6380
AZURE_READY=true
KEY_VAULT_URL=https://your-keyvault.vault.azure.net/
```

### 3. Deploy to Azure Container Apps

The containers are ready for Azure Container Apps with:
- Health checks configured
- Non-root user
- Proper resource limits
- Environment-based configuration

## Monitoring

### Container Stats
```bash
docker stats
```

### Service Health
```bash
# Check MCP server health
curl -k https://localhost/health

# Check Redis
docker-compose exec redis redis-cli ping
```

### Resource Usage
```bash
# View resource consumption
docker-compose top
```

## Troubleshooting

### Certificate Errors in VS Code
- Ensure `"rejectUnauthorized": false` is set for self-signed certs
- Check certificate file permissions

### Connection Refused
```bash
# Verify all services are healthy
docker-compose ps

# Check NGINX is listening
docker-compose exec nginx netstat -tlnp
```

### Session Errors
```bash
# Check Redis connection
docker-compose exec redis redis-cli
> ping
> keys session:*
```

### CORS Issues
- Check browser console for specific CORS errors
- Verify ALLOWED_ORIGINS in environment
- Check NGINX CORS headers are being set

## File Structure

```
mcp-style-guide-docker/
├── src/
│   ├── mcp_http_server.py      # FastAPI MCP server
│   ├── style_analyzer.py       # Microsoft Style Guide analyzer
│   ├── config.py              # Configuration management
│   └── requirements.txt       # Python dependencies
├── docker/
│   ├── Dockerfile.mcp         # MCP server image
│   ├── Dockerfile.nginx       # NGINX image
│   └── nginx/
│       ├── nginx.conf         # Main NGINX config
│       ├── conf.d/
│       │   └── mcp-server.conf # MCP server config
│       └── ssl/               # SSL certificates
├── scripts/
│   ├── generate-certs.sh      # Certificate generation
│   ├── build.sh              # Build script
│   └── deploy.sh             # Deployment script
├── docker-compose.yml         # Base compose config
├── docker-compose.prod.yml    # Production overrides
├── .dockerignore             # Docker ignore rules
├── .env.example              # Environment template
└── logs/                     # Application logs
```

## Security Notes

- This deployment has **no authentication** as requested
- HTTPS is enforced with modern TLS configuration
- Non-root user in containers
- Health checks don't expose sensitive data
- Session management with Redis TTL

## Performance

- NGINX configured for optimal performance
- Gzip compression enabled
- Connection pooling
- Health checks for auto-recovery
- Production-ready logging

For more information about the MCP protocol and VS Code integration, see the main project documentation.