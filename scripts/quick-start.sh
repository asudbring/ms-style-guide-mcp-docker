#!/bin/bash

# Quick start script for MCP Style Guide Docker deployment
set -e

echo "MCP Style Guide Server - Docker Quick Start"
echo "=========================================="

# Create directory structure
echo "Creating directory structure..."
mkdir -p src docker/nginx/ssl docker/nginx/conf.d scripts logs/mcp logs/nginx .vscode .github/workflows

# Create marker file for git
touch docker/nginx/ssl/.gitkeep

# Check if essential files exist
if [ ! -f "src/mcp_http_server.py" ]; then
    echo "ERROR: Required source files are missing!"
    echo "Please ensure all artifact files are in place:"
    echo "  - src/mcp_http_server.py"
    echo "  - src/style_analyzer.py"
    echo "  - src/config.py"
    echo "  - src/requirements.txt"
    echo "  - docker/Dockerfile.mcp"
    echo "  - docker/Dockerfile.nginx"
    echo "  - etc..."
    exit 1
fi

# Make all scripts executable
echo "Making scripts executable..."
chmod +x scripts/*.sh

# Generate certificates
echo "Generating self-signed certificates..."
./scripts/generate-certs.sh

# Build containers
echo "Building Docker containers..."
./scripts/build.sh

# Deploy services
echo "Deploying services..."
./scripts/deploy.sh

# Wait for services
echo "Waiting for services to be healthy..."
sleep 15

# Run tests
echo "Running deployment tests..."
./scripts/test-deployment.sh

echo ""
echo "=========================================="
echo "✅ Deployment Complete!"
echo ""
echo "MCP Server is available at: https://localhost/"
echo ""

# Auto-install MCP configuration if requested
if [[ "${AUTO_INSTALL_MCP}" == "true" ]] || [[ "${AUTO_INSTALL_MCP}" == "1" ]]; then
    echo "🔧 Auto-installing VS Code MCP configuration..."
    if ./scripts/install-mcp-config.sh --quiet; then
        echo "✅ VS Code MCP configuration installed automatically!"
    else
        echo "⚠️  Auto-installation failed. You can run it manually:"
        echo "  ./scripts/install-mcp-config.sh"
    fi
    echo ""
fi

echo "Next steps:"
if [[ "${AUTO_INSTALL_MCP}" == "true" ]] || [[ "${AUTO_INSTALL_MCP}" == "1" ]]; then
    echo "1. Restart VS Code to load the new MCP configuration"
    echo "2. Test with: @microsoft-style-guide-docker analyze \"Your text here\""
else
    echo "1. Run automatic VS Code configuration:"
    echo "   ./scripts/install-mcp-config.sh"
    echo "2. OR manually copy .vscode/mcp-config.json to your VS Code user settings"
    echo "3. Restart VS Code"
    echo "4. Test with: @microsoft-style-guide-docker analyze \"Your text here\""
fi
echo ""
echo "Useful commands:"
echo "  make logs     - View logs"
echo "  make test     - Run tests"
echo "  make restart  - Restart services"
echo "  make help     - Show all commands"
echo ""