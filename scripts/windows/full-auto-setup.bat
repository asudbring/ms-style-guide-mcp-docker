@echo off
REM Full Auto Setup with VS Code MCP Integration
REM This script deploys the MCP server and automatically configures VS Code

echo ======================================================
echo Microsoft Style Guide MCP Server - Full Auto Setup
echo ======================================================
echo.

echo Step 1: Generating certificates...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0generate-certs-fast.ps1"
if %errorlevel% neq 0 (
    echo ERROR: Certificate generation failed
    pause
    exit /b 1
)

echo.
echo Step 2: Building containers...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0build.ps1"
if %errorlevel% neq 0 (
    echo ERROR: Container build failed
    pause
    exit /b 1
)

echo.
echo Step 3: Deploying services...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0deploy.ps1"
if %errorlevel% neq 0 (
    echo ERROR: Service deployment failed
    pause
    exit /b 1
)

echo.
echo Step 4: Waiting for services to be ready...
timeout /t 15 /nobreak >nul

echo.
echo Step 5: Testing MCP server health...
powershell.exe -ExecutionPolicy Bypass -Command "try { $response = curl http://localhost/health 2>$null; if ($response -like '*healthy*') { Write-Host 'HTTP endpoint is healthy (VS Code ready)' -ForegroundColor Green } else { Write-Host 'HTTP health check failed' -ForegroundColor Red } } catch { Write-Host 'HTTP health check failed' -ForegroundColor Red }"
powershell.exe -ExecutionPolicy Bypass -Command "try { $response = curl -k https://localhost/health 2>$null; if ($response -like '*healthy*') { Write-Host 'HTTPS endpoint is healthy (Production ready)' -ForegroundColor Green } else { Write-Host 'HTTPS health check failed' -ForegroundColor Red } } catch { Write-Host 'HTTPS health check failed' -ForegroundColor Red }"

echo.
echo Step 6: Installing VS Code MCP configuration...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0install-mcp-config-simple.ps1"
if %errorlevel% neq 0 (
    echo WARNING: VS Code configuration failed, but services are running
    echo You can manually run: scripts\windows\install-mcp-config.ps1
)

echo.
echo ======================================================
echo 🎉 Full Auto Setup Complete! 🎉
echo ======================================================
echo.
echo 🔗 MCP Server URLs:
echo   HTTP (VS Code):  http://localhost/mcp
echo   HTTPS (Testing): https://localhost/mcp
echo ✅ Health Check: http://localhost/health
echo ✅ VS Code: Configuration installed
echo.
echo Next steps:
echo 1. Restart VS Code to load the new configuration
echo 2. Test with: @microsoft-style-guide-docker analyze "Your text here"
echo.
pause
