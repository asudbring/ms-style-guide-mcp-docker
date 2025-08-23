#!/bin/bash

# Check prerequisites for MCP Docker deployment
set -e

echo "Checking prerequisites for MCP Style Guide Docker deployment..."
echo "=============================================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

# Function to check command exists
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✓ $2 is installed${NC}"
        return 0
    else
        echo -e "${RED}✗ $2 is not installed${NC}"
        echo "  Please install $2: $3"
        ((ERRORS++))
        return 1
    fi
}

# Function to check version
check_version() {
    local current_version=$1
    local required_version=$2
    local name=$3
    
    if [ "$(printf '%s\n' "$required_version" "$current_version" | sort -V | head -n1)" = "$required_version" ]; then
        echo -e "${GREEN}✓ $name version $current_version meets requirement (>= $required_version)${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ $name version $current_version is below recommended $required_version${NC}"
        ((WARNINGS++))
        return 1
    fi
}

# Check Docker
if check_command docker "Docker" "https://docs.docker.com/get-docker/"; then
    DOCKER_VERSION=$(docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    check_version "$DOCKER_VERSION" "20.10.0" "Docker"
fi

# Check Docker Compose
if command -v docker-compose &> /dev/null; then
    echo -e "${GREEN}✓ Docker Compose (standalone) is installed${NC}"
    COMPOSE_VERSION=$(docker-compose --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    check_version "$COMPOSE_VERSION" "2.0.0" "Docker Compose"
elif docker compose version &> /dev/null; then
    echo -e "${GREEN}✓ Docker Compose (plugin) is installed${NC}"
    COMPOSE_VERSION=$(docker compose version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    check_version "$COMPOSE_VERSION" "2.0.0" "Docker Compose"
else
    echo -e "${RED}✗ Docker Compose is not installed${NC}"
    echo "  Please install Docker Compose: https://docs.docker.com/compose/install/"
    ((ERRORS++))
fi

# Check OpenSSL
check_command openssl "OpenSSL" "Usually pre-installed on most systems"

# Check Python (for local testing)
if check_command python3 "Python 3" "https://www.python.org/downloads/"; then
    PYTHON_VERSION=$(python3 --version | grep -oE '[0-9]+\.[0-9]+')
    check_version "$PYTHON_VERSION" "3.8" "Python"
fi

# Check available ports
echo -e "\nChecking port availability..."
for port in 443; do
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${RED}✗ Port $port is already in use${NC}"
        echo "  Please stop the service using this port or change the port in docker-compose.yml"
        ((ERRORS++))
    else
        echo -e "${GREEN}✓ Port $port is available${NC}"
    fi
done

# Check Docker daemon
echo -e "\nChecking Docker daemon..."
if docker info &> /dev/null; then
    echo -e "${GREEN}✓ Docker daemon is running${NC}"
else
    echo -e "${RED}✗ Docker daemon is not running${NC}"
    echo "  Please start Docker Desktop or the Docker service"
    ((ERRORS++))
fi

# Check disk space
echo -e "\nChecking disk space..."
AVAILABLE_SPACE=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$AVAILABLE_SPACE" -lt 5 ]; then
    echo -e "${YELLOW}⚠ Low disk space: ${AVAILABLE_SPACE}GB available${NC}"
    echo "  Recommended: At least 5GB free space"
    ((WARNINGS++))
else
    echo -e "${GREEN}✓ Sufficient disk space: ${AVAILABLE_SPACE}GB available${NC}"
fi

# Check if VS Code is installed (optional)
echo -e "\nChecking optional components..."
if check_command code "Visual Studio Code" "https://code.visualstudio.com/"; then
    # Check for MCP extension
    if code --list-extensions 2>/dev/null | grep -q "modelcontextprotocol"; then
        echo -e "${GREEN}✓ VS Code MCP extension is installed${NC}"
    else
        echo -e "${YELLOW}⚠ VS Code MCP extension not found${NC}"
        echo "  Install it from the VS Code marketplace"
        ((WARNINGS++))
    fi
fi

# Summary
echo -e "\n=============================================================="
if [ $ERRORS -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}All prerequisites are met! You can proceed with deployment.${NC}"
    else
        echo -e "${YELLOW}Prerequisites check completed with $WARNINGS warnings.${NC}"
        echo "The deployment should work, but consider addressing the warnings."
    fi
    exit 0
else
    echo -e "${RED}Prerequisites check failed with $ERRORS errors.${NC}"
    echo "Please install the missing components before proceeding."
    exit 1
fi