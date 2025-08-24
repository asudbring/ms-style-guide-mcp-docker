#!/bin/bash

# Complete Deployment script - One-stop solution
# Handles certificates, building, and deployment

set -e

# Default options
NO_BUILD=false
NO_VSCODE=false
HELP=false

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-build)
            NO_BUILD=true
            shift
            ;;
        --no-vscode)
            NO_VSCODE=true
            shift
            ;;
        --help|-h)
            HELP=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

if [ "$HELP" = true ]; then
    echo -e "${GREEN}Microsoft Style Guide MCP Server - Complete Deployment${NC}"
    echo ""
    echo "Usage: ./deploy.sh [options]"
    echo ""
    echo "Options:"
    echo "  --no-build    Skip building containers (use existing images)"
    echo "  --no-vscode   Skip VS Code configuration setup"
    echo "  --help, -h    Show this help message"
    echo ""
    echo "This script will:"
    echo "  1. Generate SSL certificates (if needed)"
    echo "  2. Build Docker containers (unless --no-build)"
    echo "  3. Deploy services with Docker Compose"
    echo "  4. Run comprehensive health checks"
    echo "  5. Configure VS Code MCP integration (unless --no-vscode)"
    exit 0
fi

echo -e "${CYAN}======================================================${NC}"
echo -e "${GREEN}Microsoft Style Guide MCP Server - Complete Deployment${NC}"
echo -e "${CYAN}======================================================${NC}"
echo ""

# Get the project root directory (one level up from scripts)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo -e "${CYAN}Project root: $PROJECT_ROOT${NC}"

# Change to project root directory
cd "$PROJECT_ROOT"

# Step 1: Generate SSL certificates if needed
echo -e "${YELLOW}Step 1: Checking SSL certificates...${NC}"
if [ ! -f "docker/nginx/ssl/cert.pem" ]; then
    echo -e "${YELLOW}Certificates not found. Generating...${NC}"
    
    # Inline certificate generation (matches PowerShell version)
    CERT_DIR="docker/nginx/ssl"
    DOMAIN="localhost"
    
    # Create directory if not exists
    mkdir -p "$CERT_DIR"
    
    # Generate certificates (simplified approach matching PowerShell)
    echo -e "${YELLOW}Generating private key...${NC}"
    openssl genrsa -out "$CERT_DIR/key.pem" 2048 2>/dev/null
    
    echo -e "${YELLOW}Generating certificate...${NC}"
    # Use MSYS_NO_PATHCONV to prevent Git Bash path conversion
    MSYS_NO_PATHCONV=1 openssl req -new -key "$CERT_DIR/key.pem" -out "$CERT_DIR/csr.pem" \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=$DOMAIN" 2>/dev/null
    openssl x509 -req -days 365 -in "$CERT_DIR/csr.pem" \
        -signkey "$CERT_DIR/key.pem" -out "$CERT_DIR/cert.pem" 2>/dev/null
    rm -f "$CERT_DIR/csr.pem"
    
    echo -e "${GREEN}✓ SSL certificates generated successfully${NC}"
else
    echo -e "${GREEN}✓ SSL certificates already exist${NC}"
fi

# Step 2: Build containers (unless --no-build)
if [ "$NO_BUILD" = false ]; then
    echo -e "${YELLOW}Step 2: Building Docker containers...${NC}"
    docker-compose build --no-cache
    echo -e "${GREEN}✓ Containers built successfully${NC}"
else
    echo -e "${YELLOW}Step 2: Skipping container build (--no-build specified)${NC}"
fi

# Step 3: Stop existing containers
echo -e "${YELLOW}Step 3: Stopping existing containers...${NC}"
docker-compose down --remove-orphans 2>/dev/null || true
echo -e "${GREEN}✓ Existing containers stopped${NC}"

# Step 4: Deploy services
echo -e "${YELLOW}Step 4: Starting services...${NC}"
docker-compose up -d
echo -e "${GREEN}✓ Services started${NC}"

# Step 5: Health checks
echo -e "${YELLOW}Step 5: Running health checks...${NC}"
echo "Waiting for services to initialize..."
sleep 10

# Check if containers are running
if ! docker-compose ps | grep -q "Up"; then
    echo -e "${RED}✗ Some containers failed to start${NC}"
    docker-compose logs --tail=20
    exit 1
fi

# Test HTTP endpoint (internal)
echo "Testing internal MCP server endpoint..."
if docker-compose exec -T mcp-server curl -f http://localhost:8000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Internal MCP server endpoint is healthy${NC}"
else
    echo -e "${RED}✗ Internal MCP server endpoint failed${NC}"
    exit 1
fi

# Test HTTPS endpoint (external)
echo "Testing external HTTPS endpoint..."
if curl -k -f https://localhost/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ External HTTPS endpoint is healthy${NC}"
else
    echo -e "${RED}✗ External HTTPS endpoint failed${NC}"
    exit 1
fi

# Test HTTP endpoint (external - for MCP client)
echo "Testing external HTTP endpoint..."
if curl -f http://localhost/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ External HTTP endpoint is healthy${NC}"
else
    echo -e "${RED}✗ External HTTP endpoint failed${NC}"
    exit 1
fi

# Test MCP endpoint
echo "Testing MCP functionality..."
MCP_RESPONSE=$(curl -s -X POST http://localhost/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}')

if echo "$MCP_RESPONSE" | grep -q "tools"; then
    echo -e "${GREEN}✓ MCP endpoint is responding correctly${NC}"
else
    echo -e "${RED}✗ MCP endpoint not responding correctly${NC}"
    echo "Response: $MCP_RESPONSE"
    exit 1
fi

echo -e "${GREEN}✓ All health checks passed!${NC}"

# Step 6: VS Code Integration (unless --no-vscode)
if [ "$NO_VSCODE" = false ]; then
    echo -e "${YELLOW}Step 6: Configuring VS Code MCP integration...${NC}"
    
    # Check if install script exists and run it
    if [ -f "scripts/install-mcp-config.sh" ]; then
        chmod +x scripts/install-mcp-config.sh
        if ./scripts/install-mcp-config.sh --force; then
            echo -e "${GREEN}✓ VS Code MCP configuration complete${NC}"
        else
            echo -e "${YELLOW}⚠ VS Code configuration failed, but services are running${NC}"
            echo -e "${YELLOW}You can manually run: scripts/install-mcp-config.sh${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ VS Code installation script not found, skipping...${NC}"
    fi
else
    echo -e "${YELLOW}Step 6: Skipping VS Code configuration (--no-vscode specified)${NC}"
fi

# Final summary
echo ""
echo -e "${CYAN}======================================================${NC}"
echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo -e "${CYAN}======================================================${NC}"
echo ""
echo -e "${GREEN}Services are running and healthy:${NC}"
echo "  • HTTPS endpoint: https://localhost/"
echo "  • HTTP endpoint:  http://localhost/"
echo "  • MCP endpoint:   http://localhost/mcp"
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "  1. Open VS Code"
echo "  2. Open Copilot Chat"
echo "  3. Type '@ms-style' to use the style guide tools"
echo ""
echo -e "${YELLOW}To stop services:${NC} docker-compose down"
echo -e "${YELLOW}To view logs:${NC}    docker-compose logs -f"
echo ""
