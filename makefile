.PHONY: help build deploy stop restart logs test clean certs

# Default target
help:
	@echo "MCP Style Guide Server - Docker Deployment"
	@echo "========================================="
	@echo "Available commands:"
	@echo "  make certs      - Generate self-signed certificates"
	@echo "  make build      - Build Docker containers"
	@echo "  make deploy     - Deploy the application"
	@echo "  make stop       - Stop all services"
	@echo "  make restart    - Restart all services"
	@echo "  make logs       - View logs (all services)"
	@echo "  make test       - Run deployment tests"
	@echo "  make clean      - Clean up containers and volumes"
	@echo "  make shell-mcp  - Open shell in MCP container"
	@echo "  make shell-redis- Open Redis CLI"

# Generate certificates
certs:
	@chmod +x scripts/generate-certs.sh
	@./scripts/generate-certs.sh

# Build containers
build: certs
	@chmod +x scripts/build.sh
	@./scripts/build.sh

# Deploy application
deploy:
	@chmod +x scripts/deploy.sh
	@./scripts/deploy.sh

# Stop all services
stop:
	@docker-compose down

# Restart all services
restart: stop deploy

# View logs
logs:
	@docker-compose logs -f

# View specific service logs
logs-mcp:
	@docker-compose logs -f mcp-server

logs-nginx:
	@docker-compose logs -f nginx

logs-redis:
	@docker-compose logs -f redis

# Run tests
test:
	@chmod +x scripts/test-deployment.sh
	@./scripts/test-deployment.sh

# Clean up
clean:
	@docker-compose down -v
	@rm -rf logs/*
	@echo "Cleaned up containers and volumes"

# Shell access
shell-mcp:
	@docker-compose exec mcp-server /bin/bash

shell-redis:
	@docker-compose exec redis redis-cli

# Development helpers
dev-rebuild:
	@docker-compose down
	@docker-compose -f docker-compose.yml build --no-cache
	@docker-compose -f docker-compose.yml up -d
	@docker-compose logs -f

# Production deployment
prod-deploy:
	@docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Show running containers
status:
	@docker-compose ps