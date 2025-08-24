@echo off
REM Quick deployment with automatic VS Code MCP configuration
REM This script deploys the MCP server and automatically configures VS Code

echo ======================================================
echo Microsoft Style Guide MCP Server - Full Auto Setup
echo ======================================================
echo.

REM Set environment variable for auto-installation
set AUTO_INSTALL_MCP=true

REM Run the main deployment script
powershell.exe -ExecutionPolicy Bypass -File "%~dp0quick-start.ps1"

echo.
echo ======================================================
echo Full setup complete!
echo ======================================================
pause
