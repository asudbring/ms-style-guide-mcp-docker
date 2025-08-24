# Build script for production deployment
# PowerShell equivalent of build.sh

$ErrorActionPreference = "Stop"

Write-Host "Building MCP Style Guide Server..." -ForegroundColor Green

# Generate certificates if not exists
if (-not (Test-Path "docker\nginx\ssl\cert.pem")) {
    Write-Host "Certificates not found. Generating..." -ForegroundColor Yellow
    & "$PSScriptRoot\generate-certs.ps1"
}

# Note: You need to manually copy or create the style_analyzer.py from your existing file
# Check if style_analyzer.py exists
if (-not (Test-Path "src\style_analyzer.py")) {
    Write-Host "WARNING: src\style_analyzer.py not found!" -ForegroundColor Red
    Write-Host "Please copy the WebEnabledStyleGuideAnalyzer class from fastmcp_style_server_web.py" -ForegroundColor Red
    Write-Host "or use the provided style_analyzer.py artifact" -ForegroundColor Red
    exit 1
}

# Build containers
Write-Host "Building containers..." -ForegroundColor Green
docker-compose -f docker-compose.yml -f docker-compose.prod.yml build --no-cache

Write-Host "Build complete!" -ForegroundColor Green
