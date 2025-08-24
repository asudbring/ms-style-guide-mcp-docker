# Check prerequisites for MCP Docker deployment
# PowerShell equivalent of check-prerequisites.sh

# Ensure we see output immediately
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "Checking prerequisites for MCP Style Guide Docker deployment..." -ForegroundColor Cyan
Write-Host "==============================================================" -ForegroundColor Cyan

$ERRORS = 0
$WARNINGS = 0

# Function to check if command exists
function Test-Command {
    param(
        [string]$CommandName,
        [string]$DisplayName,
        [string]$InstallInfo
    )
    
    Write-Host "Checking $DisplayName..." -ForegroundColor Yellow
    
    if (Get-Command $CommandName -ErrorAction SilentlyContinue) {
        Write-Host "✓ $DisplayName is installed" -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ $DisplayName is not installed" -ForegroundColor Red
        Write-Host "  Please install $DisplayName`: $InstallInfo" -ForegroundColor Red
        $script:ERRORS++
        return $false
    }
}

# Function to check version - simplified
function Test-Version {
    param(
        [string]$CurrentVersion,
        [string]$RequiredVersion,
        [string]$Name
    )
    
    if (-not $CurrentVersion) {
        Write-Host "⚠ Could not determine $Name version" -ForegroundColor Yellow
        $script:WARNINGS++
        return $false
    }
    
    try {
        if ([version]$CurrentVersion -ge [version]$RequiredVersion) {
            Write-Host "✓ $Name version $CurrentVersion meets requirement (>= $RequiredVersion)" -ForegroundColor Green
            return $true
        } else {
            Write-Host "⚠ $Name version $CurrentVersion is below recommended $RequiredVersion" -ForegroundColor Yellow
            $script:WARNINGS++
            return $false
        }
    } catch {
        Write-Host "⚠ Could not compare $Name version" -ForegroundColor Yellow
        $script:WARNINGS++
        return $false
    }
}

# Check Docker
Write-Host "`n1. Checking Docker..." -ForegroundColor Cyan
if (Test-Command "docker" "Docker" "https://docs.docker.com/get-docker/") {
    try {
        $DockerVersionOutput = docker --version 2>$null
        if ($DockerVersionOutput) {
            Write-Host "   Docker version: $DockerVersionOutput" -ForegroundColor Gray
            $DockerVersion = if ($DockerVersionOutput -match '(\d+\.\d+\.\d+)') { $Matches[1] } else { $null }
            if ($DockerVersion) {
                Test-Version $DockerVersion "20.10.0" "Docker"
            }
        }
    } catch {
        Write-Host "⚠ Could not determine Docker version" -ForegroundColor Yellow
        $script:WARNINGS++
    }
}

# Check Docker Compose
Write-Host "`n2. Checking Docker Compose..." -ForegroundColor Cyan
$composeFound = $false

# Check standalone docker-compose
if (Get-Command "docker-compose" -ErrorAction SilentlyContinue) {
    Write-Host "✓ Docker Compose (standalone) is installed" -ForegroundColor Green
    $composeFound = $true
    try {
        $ComposeVersionOutput = docker-compose --version 2>$null
        if ($ComposeVersionOutput) {
            Write-Host "   Version: $ComposeVersionOutput" -ForegroundColor Gray
            $ComposeVersion = if ($ComposeVersionOutput -match '(\d+\.\d+\.\d+)') { $Matches[1] } else { $null }
            if ($ComposeVersion) {
                Test-Version $ComposeVersion "2.0.0" "Docker Compose"
            }
        }
    } catch {
        Write-Host "⚠ Could not determine Docker Compose version" -ForegroundColor Yellow
        $script:WARNINGS++
    }
}

# Check docker compose plugin
if (-not $composeFound) {
    try {
        $composeTest = docker compose version 2>$null
        if ($LASTEXITCODE -eq 0 -and $composeTest) {
            Write-Host "✓ Docker Compose (plugin) is installed" -ForegroundColor Green
            Write-Host "   Version: $composeTest" -ForegroundColor Gray
            $composeFound = $true
            $ComposeVersion = if ($composeTest -match '(\d+\.\d+\.\d+)') { $Matches[1] } else { $null }
            if ($ComposeVersion) {
                Test-Version $ComposeVersion "2.0.0" "Docker Compose"
            }
        }
    } catch {
        # Ignore error, will be caught below
    }
}

if (-not $composeFound) {
    Write-Host "✗ Docker Compose is not installed" -ForegroundColor Red
    Write-Host "  Please install Docker Compose: https://docs.docker.com/compose/install/" -ForegroundColor Red
    $script:ERRORS++
}

# Check OpenSSL
Write-Host "`n3. Checking OpenSSL..." -ForegroundColor Cyan
$opensslFound = $false

# First check if openssl is in PATH
if (Get-Command "openssl" -ErrorAction SilentlyContinue) {
    Write-Host "✓ OpenSSL is installed" -ForegroundColor Green
    $opensslFound = $true
} else {
    # Check if OpenSSL is available through Git installation
    $gitOpenSSLPaths = @(
        "C:\Program Files\Git\usr\bin\openssl.exe",
        "C:\Program Files (x86)\Git\usr\bin\openssl.exe"
    )
    
    foreach ($path in $gitOpenSSLPaths) {
        if (Test-Path $path) {
            Write-Host "✓ OpenSSL found in Git installation: $path" -ForegroundColor Green
            try {
                $opensslVersion = & $path version 2>$null
                if ($opensslVersion) {
                    Write-Host "   Version: $opensslVersion" -ForegroundColor Gray
                }
            } catch {
                Write-Host "   Could not determine version" -ForegroundColor Yellow
            }
            $opensslFound = $true
            break
        }
    }
}

if (-not $opensslFound) {
    Write-Host "✗ OpenSSL not found" -ForegroundColor Red
    Write-Host "  Install Git for Windows or OpenSSL separately" -ForegroundColor Red
    $script:ERRORS++
}

# Check Python
Write-Host "`n4. Checking Python..." -ForegroundColor Cyan
if (Test-Command "python" "Python 3" "https://www.python.org/downloads/") {
    try {
        $PythonVersionOutput = python --version 2>$null
        if ($PythonVersionOutput) {
            Write-Host "   Version: $PythonVersionOutput" -ForegroundColor Gray
            $PythonVersion = if ($PythonVersionOutput -match '(\d+\.\d+)') { "$($Matches[1]).0" } else { $null }
            if ($PythonVersion) {
                Test-Version $PythonVersion "3.8.0" "Python"
            }
        }
    } catch {
        Write-Host "⚠ Could not determine Python version" -ForegroundColor Yellow
        $script:WARNINGS++
    }
}

# Check available ports
Write-Host "`n5. Checking port availability..." -ForegroundColor Cyan
$portsToCheck = @(443)
foreach ($port in $portsToCheck) {
    Write-Host "Checking port $port..." -ForegroundColor Yellow
    try {
        $connections = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
        if ($connections) {
            Write-Host "✗ Port $port is already in use" -ForegroundColor Red
            Write-Host "  Please stop the service using this port or change the port in docker-compose.yml" -ForegroundColor Red
            $script:ERRORS++
        } else {
            Write-Host "✓ Port $port is available" -ForegroundColor Green
        }
    } catch {
        Write-Host "✓ Port $port appears to be available" -ForegroundColor Green
    }
}

# Check Docker daemon
Write-Host "`n6. Checking Docker daemon..." -ForegroundColor Cyan
try {
    $dockerInfo = docker info 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Docker daemon is running" -ForegroundColor Green
    } else {
        Write-Host "✗ Docker daemon is not running" -ForegroundColor Red
        Write-Host "  Please start Docker Desktop or the Docker service" -ForegroundColor Red
        $script:ERRORS++
    }
} catch {
    Write-Host "✗ Docker daemon is not running" -ForegroundColor Red
    Write-Host "  Please start Docker Desktop or the Docker service" -ForegroundColor Red
    $script:ERRORS++
}

# Check disk space
Write-Host "`n7. Checking disk space..." -ForegroundColor Cyan
try {
    $drive = Get-PSDrive -Name (Get-Location).Drive.Name
    $freeSpaceGB = [math]::Round($drive.Free / 1GB, 1)
    if ($freeSpaceGB -lt 5) {
        Write-Host "⚠ Low disk space: ${freeSpaceGB}GB available" -ForegroundColor Yellow
        Write-Host "  Recommended: At least 5GB free space" -ForegroundColor Yellow
        $script:WARNINGS++
    } else {
        Write-Host "✓ Sufficient disk space: ${freeSpaceGB}GB available" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠ Could not determine disk space" -ForegroundColor Yellow
    $script:WARNINGS++
}

# Check if VS Code is installed (optional)
Write-Host "`n8. Checking optional components..." -ForegroundColor Cyan
Test-Command "code" "Visual Studio Code" "https://code.visualstudio.com/" | Out-Null

# Summary
Write-Host "`n==============================================================" -ForegroundColor Cyan
Write-Host "PREREQUISITE CHECK SUMMARY" -ForegroundColor White
Write-Host "==============================================================" -ForegroundColor Cyan

if ($ERRORS -eq 0) {
    if ($WARNINGS -eq 0) {
        Write-Host "🎉 All prerequisites are met! You can proceed with deployment." -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor White
        Write-Host "1. Run: .\scripts\windows\quick-start.ps1" -ForegroundColor Cyan
        Write-Host "2. Or run individual scripts as needed" -ForegroundColor Cyan
    } else {
        Write-Host "✅ Prerequisites check completed with $WARNINGS warnings." -ForegroundColor Yellow
        Write-Host "The deployment should work, but consider addressing the warnings." -ForegroundColor Yellow
    }
    Write-Host ""
    exit 0
} else {
    Write-Host "❌ Prerequisites check failed with $ERRORS errors and $WARNINGS warnings." -ForegroundColor Red
    Write-Host "Please install the missing components before proceeding." -ForegroundColor Red
    Write-Host ""
    exit 1
}
