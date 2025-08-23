#!/bin/bash

# Deployment script
set -e

echo "Deploying MCP Style Guide Server..."

# Stop existing containers
docker-compose down

# Build if needed
if [ "$1" == "--build" ]; then
    ./scripts/build.sh
fi

# Start services
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Wait for health checks
echo "Waiting for services to be healthy..."
sleep 10

# Check health
docker-compose ps
docker-compose exec mcp-server curl -f http://localhost:8000/health
docker-compose exec nginx wget --no-check-certificate -O- https://localhost/health

echo "Deployment complete!"
echo "MCP Server is available at https://localhost/"