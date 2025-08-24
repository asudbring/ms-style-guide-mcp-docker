# Deployment script
# PowerShell equivalent of deploy-sh.sh

param(
    [switch]$Build
)

$ErrorActionPreference = "Stop"

Write-Host "Deploying MCP Style Guide Server..." -ForegroundColor Green

# Stop existing containers
Write-Host "Stopping existing containers..." -ForegroundColor Yellow
docker-compose down

# Build if needed
if ($Build) {
    & "$PSScriptRoot\build.ps1"
}

# Start services
Write-Host "Starting services..." -ForegroundColor Green
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Wait for health checks
Write-Host "Waiting for services to be healthy..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Check health
Write-Host "Checking service status..." -ForegroundColor Cyan
docker-compose ps

Write-Host "Testing MCP server health..." -ForegroundColor Cyan
try {
    docker-compose exec -T mcp-server curl -f http://localhost:8000/health
    Write-Host "✓ MCP server health check passed" -ForegroundColor Green
} catch {
    Write-Host "⚠ MCP server health check failed" -ForegroundColor Red
}

Write-Host "Testing NGINX health (HTTP for VS Code)..." -ForegroundColor Cyan
try {
    docker-compose exec -T nginx wget -O- http://localhost/health
    Write-Host "✓ NGINX HTTP health check passed" -ForegroundColor Green
} catch {
    Write-Host "⚠ NGINX HTTP health check failed" -ForegroundColor Red
}

Write-Host "Testing NGINX health (HTTPS for production)..." -ForegroundColor Cyan
try {
    docker-compose exec -T nginx wget --no-check-certificate -O- https://localhost/health
    Write-Host "✓ NGINX HTTPS health check passed" -ForegroundColor Green
} catch {
    Write-Host "⚠ NGINX HTTPS health check failed" -ForegroundColor Red
}

Write-Host "Deployment complete!" -ForegroundColor Green
Write-Host "MCP Server URLs:" -ForegroundColor Cyan
Write-Host "  HTTP (VS Code):  http://localhost/mcp" -ForegroundColor White
Write-Host "  HTTPS (Testing): https://localhost/mcp" -ForegroundColor White
