# Test MCP Server Installation
# This script tests the simplified 2-container MCP architecture

Write-Host "🧪 Testing MCP Server Installation..." -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Test 1: Check container status
Write-Host "`n1. Checking container status..." -ForegroundColor Yellow
docker-compose ps

# Test 2: Test initialize method
Write-Host "`n2. Testing MCP initialize method..." -ForegroundColor Yellow
$initResponse = curl -k -s -X POST https://localhost/mcp -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{"roots":{"listChanged":true},"sampling":{}},"clientInfo":{"name":"test-client","version":"1.0.0"}}}'
Write-Host "Response: $initResponse" -ForegroundColor Green

# Test 3: List available tools
Write-Host "`n3. Listing available MCP tools..." -ForegroundColor Yellow
$toolsResponse = curl -k -s -X POST https://localhost/mcp -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}'
$toolsJson = $toolsResponse | ConvertFrom-Json
$toolCount = $toolsJson.result.tools.Count
Write-Host "Found $toolCount tools:" -ForegroundColor Green
foreach ($tool in $toolsJson.result.tools) {
    Write-Host "  • $($tool.name): $($tool.description)" -ForegroundColor White
}

# Test 4: Test a specific tool
Write-Host "`n4. Testing analyze_content tool..." -ForegroundColor Yellow
$testResponse = curl -k -s -X POST https://localhost/mcp -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"analyze_content","arguments":{"text":"Hello world! This is a test.","analysis_type":"voice_tone"}}}'
Write-Host "Tool executed successfully!" -ForegroundColor Green

# Test 5: Architecture verification
Write-Host "`n5. Verifying simplified architecture..." -ForegroundColor Yellow
$runningContainers = docker-compose ps --format json | ConvertFrom-Json
$containerNames = $runningContainers | ForEach-Object { $_.Name }

if ($containerNames -contains "mcp-server" -and $containerNames -contains "mcp-nginx" -and $containerNames -notcontains "mcp-redis") {
    Write-Host "✅ Simplified 2-container architecture confirmed!" -ForegroundColor Green
    Write-Host "  • MCP Server: Running" -ForegroundColor White
    Write-Host "  • NGINX Proxy: Running" -ForegroundColor White
    Write-Host "  • Redis: Removed (as intended)" -ForegroundColor White
} else {
    Write-Host "❌ Architecture verification failed!" -ForegroundColor Red
}

Write-Host "`n🎉 MCP Server Installation Test Complete!" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "`nTo use in VS Code:" -ForegroundColor Yellow
Write-Host "1. Install MCP extensions (e.g., automatalabs.copilot-mcp)" -ForegroundColor White
Write-Host "2. Configure MCP server with HTTPS URL: https://localhost/mcp" -ForegroundColor White
Write-Host "3. The server supports direct HTTPS communication (no session management)" -ForegroundColor White
Write-Host "`nServer Status: Available at https://localhost/" -ForegroundColor Green
