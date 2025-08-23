#!/bin/bash

# Test script for MCP Docker deployment
set -e

echo "Testing MCP Style Guide Server Docker Deployment..."
echo "=================================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check if a command succeeded
check_result() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
    else
        echo -e "${RED}✗ $1${NC}"
        exit 1
    fi
}

# 1. Check if services are running
echo -e "\n1. Checking Docker services..."
docker-compose ps | grep -q "mcp-server.*healthy"
check_result "MCP server is healthy"

docker-compose ps | grep -q "mcp-nginx.*Up"
check_result "NGINX is running"

docker-compose ps | grep -q "mcp-redis.*healthy"
check_result "Redis is healthy"

# 2. Test health endpoint
echo -e "\n2. Testing health endpoint..."
HEALTH_RESPONSE=$(curl -sk https://localhost/health)
echo "$HEALTH_RESPONSE" | grep -q "healthy"
check_result "Health endpoint responds"

# 3. Test MCP initialization
echo -e "\n3. Testing MCP initialization..."
INIT_RESPONSE=$(curl -sk -X POST https://localhost/mcp/initialize \
  -H "Content-Type: application/json" \
  -H "X-MCP-Client-Name: test-client")
echo "$INIT_RESPONSE" | grep -q "sessionId"
check_result "MCP initialization successful"

# Extract session ID
SESSION_ID=$(echo "$INIT_RESPONSE" | grep -o '"sessionId":"[^"]*"' | cut -d'"' -f4)
echo "Session ID: $SESSION_ID"

# 4. Test tools list
echo -e "\n4. Testing MCP tools list..."
TOOLS_RESPONSE=$(curl -sk -X POST https://localhost/mcp \
  -H "Content-Type: application/json" \
  -H "Mcp-Session-Id: $SESSION_ID" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/list",
    "id": 1
  }')
echo "$TOOLS_RESPONSE" | grep -q "analyze_content"
check_result "Tools list retrieved"

# 5. Test analyze_content tool
echo -e "\n5. Testing analyze_content tool..."
ANALYZE_RESPONSE=$(curl -sk -X POST https://localhost/mcp \
  -H "Content-Type: application/json" \
  -H "Mcp-Session-Id: $SESSION_ID" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "analyze_content",
      "arguments": {
        "text": "You can easily configure the settings to meet your needs.",
        "analysis_type": "comprehensive"
      }
    },
    "id": 2
  }')
echo "$ANALYZE_RESPONSE" | grep -q "result"
check_result "Content analysis successful"

# 6. Check Redis session
echo -e "\n6. Checking Redis session storage..."
docker-compose exec redis redis-cli EXISTS "session:$SESSION_ID" | grep -q "1"
check_result "Session stored in Redis"

# 7. Test CORS headers
echo -e "\n7. Testing CORS headers..."
CORS_RESPONSE=$(curl -sk -I -X OPTIONS https://localhost/mcp \
  -H "Origin: https://vscode.dev" \
  -H "Access-Control-Request-Method: POST")
echo "$CORS_RESPONSE" | grep -q "Access-Control-Allow-Origin"
check_result "CORS headers present"

# 8. Check logs accessibility
echo -e "\n8. Checking logs..."
docker-compose logs --tail=5 mcp-server > /dev/null 2>&1
check_result "MCP server logs accessible"

docker-compose logs --tail=5 nginx > /dev/null 2>&1
check_result "NGINX logs accessible"

# Summary
echo -e "\n=================================================="
echo -e "${GREEN}All tests passed! The MCP server is ready for use.${NC}"
echo -e "\nYou can now:"
echo "1. Configure VS Code with the provided mcp-config.json"
echo "2. Access the server at https://localhost/mcp"
echo "3. View logs with: docker-compose logs -f"
echo -e "\nSession ID for testing: $SESSION_ID"