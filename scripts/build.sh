#!/bin/bash

# Build script for production deployment
set -e

echo "Building MCP Style Guide Server..."

# Generate certificates if not exists
if [ ! -f "docker/nginx/ssl/cert.pem" ]; then
    echo "Certificates not found. Generating..."
    ./scripts/generate-certs.sh
fi

# Note: You need to manually copy or create the style_analyzer.py from your existing file
# Check if style_analyzer.py exists
if [ ! -f "src/style_analyzer.py" ]; then
    echo "WARNING: src/style_analyzer.py not found!"
    echo "Please copy the WebEnabledStyleGuideAnalyzer class from fastmcp_style_server_web.py"
    echo "or use the provided style_analyzer.py artifact"
    exit 1
fi

# Build containers
docker-compose -f docker-compose.yml -f docker-compose.prod.yml build --no-cache

echo "Build complete!"