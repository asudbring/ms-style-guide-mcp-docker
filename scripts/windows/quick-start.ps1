# Quick start script for MCP Style Guide Docker deployment
# PowerShell equivalent of quick-start.sh

$ErrorActionPreference = "Stop"

Write-Host "MCP Style Guide Server - Docker Quick Start" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Create directory structure
Write-Host "Creating directory structure..." -ForegroundColor Yellow
$directories = @(
    "src",
    "docker\nginx\ssl",
    "docker\nginx\conf.d",
    "scripts",
    "logs\mcp",
    "logs\nginx",
    ".vscode",
    ".github\workflows"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# Create marker file for git
if (-not (Test-Path "docker\nginx\ssl\.gitkeep")) {
    New-Item -ItemType File -Path "docker\nginx\ssl\.gitkeep" -Force | Out-Null
}

# Check if essential files exist
if (-not (Test-Path "src\mcp_http_server.py")) {
    Write-Host "ERROR: Required source files are missing!" -ForegroundColor Red
    Write-Host "Please ensure all artifact files are in place:" -ForegroundColor Red
    Write-Host "  - src\mcp_http_server.py" -ForegroundColor Red
    Write-Host "  - src\style_analyzer.py" -ForegroundColor Red
    Write-Host "  - src\mcp_config.py" -ForegroundColor Red
    Write-Host "  - src\requirements.txt" -ForegroundColor Red
    Write-Host "  - docker\dockerfile.mcp" -ForegroundColor Red
    Write-Host "  - docker\dockerfile.nginx" -ForegroundColor Red
    Write-Host "  - etc..." -ForegroundColor Red
    exit 1
}

# Generate certificates
Write-Host "Generating self-signed certificates..." -ForegroundColor Yellow
try {
    & "$PSScriptRoot\generate-certs.ps1"
    if ($LASTEXITCODE -ne 0) {
        throw "Certificate generation failed with exit code $LASTEXITCODE"
    }
} catch {
    Write-Host "ERROR: Certificate generation failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Build containers
Write-Host "Building Docker containers..." -ForegroundColor Yellow
try {
    & "$PSScriptRoot\build.ps1"
    if ($LASTEXITCODE -ne 0) {
        throw "Container build failed with exit code $LASTEXITCODE"
    }
} catch {
    Write-Host "ERROR: Container build failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Deploy services
Write-Host "Deploying services..." -ForegroundColor Yellow
try {
    & "$PSScriptRoot\deploy.ps1"
    if ($LASTEXITCODE -ne 0) {
        throw "Service deployment failed with exit code $LASTEXITCODE"
    }
} catch {
    Write-Host "ERROR: Service deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Wait for services
Write-Host "Waiting for services to be healthy..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Run tests
Write-Host "Running deployment tests..." -ForegroundColor Yellow
try {
    & "$PSScriptRoot\test-deployment.ps1"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "WARNING: Deployment tests failed, but services may still be running" -ForegroundColor Yellow
    }
} catch {
    Write-Host "WARNING: Could not run deployment tests: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "✅ Deployment Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "MCP Server is available at: https://localhost/" -ForegroundColor Cyan
Write-Host ""

# Auto-install MCP configuration if requested
$autoInstall = $env:AUTO_INSTALL_MCP
if ($autoInstall -eq "true" -or $autoInstall -eq "1") {
    Write-Host "🔧 Auto-installing VS Code MCP configuration..." -ForegroundColor Cyan
    try {
        & "$PSScriptRoot\install-mcp-config.ps1" -Quiet
        Write-Host "✅ VS Code MCP configuration installed automatically!" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️  Auto-installation failed. You can run it manually:" -ForegroundColor Yellow
        Write-Host "  .\scripts\windows\install-mcp-config.ps1" -ForegroundColor Gray
    }
    Write-Host ""
}

Write-Host "Next steps:" -ForegroundColor White
if ($autoInstall -eq "true" -or $autoInstall -eq "1") {
    Write-Host "1. Restart VS Code to load the new MCP configuration" -ForegroundColor White
    Write-Host "2. Test with: @microsoft-style-guide-docker analyze `"Your text here`"" -ForegroundColor White
} else {
    Write-Host "1. Run automatic VS Code configuration:" -ForegroundColor White
    Write-Host "   .\scripts\windows\install-mcp-config.ps1" -ForegroundColor Gray
    Write-Host "2. OR manually copy .vscode\mcp-config.json to your VS Code user settings" -ForegroundColor White
    Write-Host "3. Restart VS Code" -ForegroundColor White
    Write-Host "4. Test with: @microsoft-style-guide-docker analyze `"Your text here`"" -ForegroundColor White
}
Write-Host ""
Write-Host "Useful commands:" -ForegroundColor White
Write-Host "  make logs     - View logs" -ForegroundColor White
Write-Host "  make test     - Run tests" -ForegroundColor White
Write-Host "  make restart  - Restart services" -ForegroundColor White
Write-Host "  make help     - Show all commands" -ForegroundColor White
Write-Host ""
