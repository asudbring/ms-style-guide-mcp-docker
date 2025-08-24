# Complete Deployment script - One-stop solution
# Handles certificates, building, and deployment

param(
    [switch]$NoBuild,
    [switch]$NoVSCode,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

if ($Help) {
    Write-Host "Microsoft Style Guide MCP Server - Complete Deployment" -ForegroundColor Green
    Write-Host ""
    Write-Host "Usage: .\deploy.ps1 [options]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -NoBuild    Skip building containers (use existing images)"
    Write-Host "  -NoVSCode   Skip VS Code configuration setup"
    Write-Host "  -Help       Show this help message"
    Write-Host ""
    Write-Host "This script will:"
    Write-Host "  1. Generate SSL certificates (if needed)"
    Write-Host "  2. Build Docker containers (unless -NoBuild)"
    Write-Host "  3. Deploy services with Docker Compose"
    Write-Host "  4. Run comprehensive health checks"
    Write-Host "  5. Configure VS Code MCP integration (unless -NoVSCode)"
    exit 0
}

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "Microsoft Style Guide MCP Server - Complete Deployment" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

# Get the project root directory (two levels up from scripts/windows)
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Write-Host "Project root: $ProjectRoot" -ForegroundColor Cyan

# Change to project root directory
Push-Location $ProjectRoot

try {
    # Step 1: Generate SSL certificates if needed
    Write-Host "Step 1: Checking SSL certificates..." -ForegroundColor Yellow
    if (-not (Test-Path "docker\nginx\ssl\cert.pem")) {
        Write-Host "Certificates not found. Generating..." -ForegroundColor Yellow
        
        # Inline certificate generation (from generate-certs-fast.ps1)
        $CERT_DIR = "docker\nginx\ssl"
        $DOMAIN = "localhost"

        # Find OpenSSL executable
        $OPENSSL_PATH = $null
        $gitOpenSSLPaths = @(
            "C:\Program Files\Git\usr\bin\openssl.exe",
            "C:\Program Files (x86)\Git\usr\bin\openssl.exe"
        )

        foreach ($path in $gitOpenSSLPaths) {
            if (Test-Path $path) {
                $OPENSSL_PATH = $path
                break
            }
        }

        if (-not $OPENSSL_PATH) {
            if (Get-Command "openssl" -ErrorAction SilentlyContinue) {
                $OPENSSL_PATH = "openssl"
            } else {
                Write-Host "[ERROR] OpenSSL not found!" -ForegroundColor Red
                Write-Host "Please install Git for Windows or OpenSSL" -ForegroundColor Red
                exit 1
            }
        }

        Write-Host "Using OpenSSL at: $OPENSSL_PATH" -ForegroundColor Gray
        
        # Create directory if not exists
        if (-not (Test-Path $CERT_DIR)) {
            New-Item -ItemType Directory -Path $CERT_DIR -Force | Out-Null
        }

        # Generate certificates
        Write-Host "Generating private key..." -ForegroundColor Gray
        & $OPENSSL_PATH genrsa -out "$CERT_DIR\key.pem" 2048 2>$null
        
        Write-Host "Generating certificate..." -ForegroundColor Gray
        & $OPENSSL_PATH req -new -key "$CERT_DIR\key.pem" -out "$CERT_DIR\csr.pem" -subj "/C=US/ST=State/L=City/O=Organization/CN=$DOMAIN" 2>$null
        & $OPENSSL_PATH x509 -req -days 365 -in "$CERT_DIR\csr.pem" -signkey "$CERT_DIR\key.pem" -out "$CERT_DIR\cert.pem" 2>$null
        Remove-Item "$CERT_DIR\csr.pem" -Force -ErrorAction SilentlyContinue
        
        Write-Host "[OK] SSL certificates generated successfully" -ForegroundColor Green
    } else {
        Write-Host "[OK] SSL certificates already exist" -ForegroundColor Green
    }

    # Step 2: Build containers (unless -NoBuild)
    if (-not $NoBuild) {
        Write-Host ""
        Write-Host "Step 2: Building Docker containers..." -ForegroundColor Yellow
        
        # Check if style_analyzer.py exists
        if (-not (Test-Path "src\style_analyzer.py")) {
            Write-Host "[ERROR] src\style_analyzer.py not found!" -ForegroundColor Red
            Write-Host "Please copy the WebEnabledStyleGuideAnalyzer class from your existing file" -ForegroundColor Red
            exit 1
        }

        docker-compose -f docker-compose.yml -f docker-compose.prod.yml build --no-cache
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[ERROR] Container build failed" -ForegroundColor Red
            exit 1
        }
        Write-Host "[OK] Containers built successfully" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "Step 2: Skipping container build (-NoBuild flag)" -ForegroundColor Yellow
    }

    # Step 3: Deploy services
    # Step 3: Deploy services
    Write-Host ""
    Write-Host "Step 3: Deploying services..." -ForegroundColor Yellow
    
    # Stop existing containers
    Write-Host "Stopping existing containers..." -ForegroundColor Gray
    docker-compose down

    # Start services
    Write-Host "Starting services..." -ForegroundColor Gray
    docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Service deployment failed" -ForegroundColor Red
        exit 1
    }

    # Wait for services to be ready
    Write-Host "Waiting for services to be ready..." -ForegroundColor Gray
    Start-Sleep -Seconds 15

    Write-Host "[OK] Services deployed successfully" -ForegroundColor Green

    # Step 4: Comprehensive health checks
    Write-Host ""
    Write-Host "Step 4: Running health checks..." -ForegroundColor Yellow

    # Check container status
    Write-Host "Container status:" -ForegroundColor Gray
    docker-compose ps

    # Test MCP server health
    Write-Host "Testing MCP server health..." -ForegroundColor Gray
    try {
        docker-compose exec -T mcp-server curl -f http://localhost:8000/health | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] MCP server health check passed" -ForegroundColor Green
        } else {
            Write-Host "[WARN] MCP server health check failed" -ForegroundColor Red
        }
    } catch {
        Write-Host "[WARN] MCP server health check failed: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Test NGINX HTTP endpoint (for VS Code)
    Write-Host "Testing HTTP endpoint (VS Code)..." -ForegroundColor Gray
    try {
        curl.exe -f http://localhost/health | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] HTTP endpoint health check passed" -ForegroundColor Green
        } else {
            Write-Host "[WARN] HTTP endpoint health check failed" -ForegroundColor Red
        }
    } catch {
        Write-Host "[WARN] HTTP endpoint health check failed: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Test NGINX HTTPS endpoint (for production)
    Write-Host "Testing HTTPS endpoint (production)..." -ForegroundColor Gray
    try {
        curl.exe -k https://localhost/health | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] HTTPS endpoint health check passed" -ForegroundColor Green
        } else {
            Write-Host "[WARN] HTTPS endpoint health check failed" -ForegroundColor Red
        }
    } catch {
        Write-Host "[WARN] HTTPS endpoint health check failed: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Step 5: VS Code configuration (unless -NoVSCode)
    if (-not $NoVSCode) {
        Write-Host ""
        Write-Host "Step 5: Configuring VS Code MCP integration..." -ForegroundColor Yellow
        
        $vsCodeConfigScript = "$PSScriptRoot\install-mcp-config-simple.ps1"
        if (Test-Path $vsCodeConfigScript) {
            try {
                & $vsCodeConfigScript
                Write-Host "[OK] VS Code configuration completed" -ForegroundColor Green
            } catch {
                Write-Host "[WARN] VS Code configuration failed, but services are running" -ForegroundColor Yellow
                Write-Host "You can manually run: scripts\windows\install-mcp-config-simple.ps1" -ForegroundColor Gray
            }
        } else {
            Write-Host "[WARN] VS Code configuration script not found" -ForegroundColor Yellow
        }
    } else {
        Write-Host ""
        Write-Host "Step 5: Skipping VS Code configuration (-NoVSCode flag)" -ForegroundColor Yellow
    }

    # Success summary
    Write-Host ""
    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host "🎉 Deployment Complete! 🎉" -ForegroundColor Green
    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🔗 MCP Server URLs:" -ForegroundColor Cyan
    Write-Host "  HTTP (VS Code):  http://localhost/mcp" -ForegroundColor White
    Write-Host "  HTTPS (Testing): https://localhost/mcp" -ForegroundColor White
    Write-Host "  Health Check:    http://localhost/health" -ForegroundColor White
    Write-Host ""
    if (-not $NoVSCode) {
        Write-Host "✅ VS Code: Configuration installed" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "1. Restart VS Code to load the new configuration" -ForegroundColor White
        Write-Host "2. Test with: @microsoft-style-guide-docker analyze `"Your text here`"" -ForegroundColor White
    } else {
        Write-Host "ℹ️  VS Code: Configuration skipped (use -NoVSCode flag to enable)" -ForegroundColor Gray
    }
    Write-Host ""

} finally {
    # Always return to original directory
    Pop-Location
}