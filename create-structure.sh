#!/bin/bash

# Create directory structure for MCP Style Guide Docker deployment
echo "Creating directory structure for MCP Style Guide Docker deployment..."

# Create all directories
mkdir -p src
mkdir -p docker/nginx/ssl
mkdir -p docker/nginx/conf.d
mkdir -p scripts
mkdir -p logs/mcp
mkdir -p logs/nginx
mkdir -p .vscode
mkdir -p .github/workflows

# Create .gitkeep for SSL directory
touch docker/nginx/ssl/.gitkeep

echo "Directory structure created successfully!"
echo ""
echo "Now place the artifact files in their respective directories:"
echo ""
echo "src/"
echo "  ├── mcp_http_server.py"
echo "  ├── config.py"
echo "  ├── style_analyzer.py"
echo "  └── requirements.txt"
echo ""
echo "docker/"
echo "  ├── Dockerfile.mcp"
echo "  ├── Dockerfile.nginx"
echo "  └── nginx/"
echo "      ├── nginx.conf"
echo "      ├── conf.d/"
echo "      │   └── mcp-server.conf"
echo "      └── ssl/"
echo "          └── .gitkeep"
echo ""
echo "scripts/"
echo "  ├── generate-certs.sh"
echo "  ├── build.sh"
echo "  ├── deploy.sh"
echo "  ├── test-deployment.sh"
echo "  ├── check-prerequisites.sh"
echo "  └── quick-start.sh"
echo ""
echo ".vscode/"
echo "  └── mcp-config.json"
echo ""
echo ".github/workflows/"
echo "  └── docker-build.yml"
echo ""
echo "Root directory:"
echo "  ├── docker-compose.yml"
echo "  ├── docker-compose.prod.yml"
echo "  ├── .dockerignore"
echo "  ├── .gitignore"
echo "  ├── .env.example"
echo "  ├── Makefile"
echo "  ├── README-DOCKER.md"
echo "  └── ARTIFACTS-LIST.md"
echo ""
echo "After placing all files, run:"
echo "  chmod +x scripts/*.sh"
echo "  ./scripts/check-prerequisites.sh"
echo "  ./quick-start.sh"