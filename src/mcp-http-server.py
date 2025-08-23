import asyncio
import json
import uuid
import logging
from datetime import datetime
from typing import Dict, Optional, Any
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, Response, HTTPException, Header
from fastapi.responses import StreamingResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import redis.asyncio as redis
import uvicorn

from style_analyzer import WebEnabledStyleGuideAnalyzer

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Session manager
class SessionManager:
    def __init__(self, redis_client):
        self.redis = redis_client
        self.ttl = 3600  # 1 hour session TTL
    
    async def create_session(self, client_info: dict) -> str:
        session_id = str(uuid.uuid4())
        session_data = {
            "id": session_id,
            "created_at": datetime.utcnow().isoformat(),
            "client_info": json.dumps(client_info),
            "last_activity": datetime.utcnow().isoformat()
        }
        
        await self.redis.hset(f"session:{session_id}", mapping=session_data)
        await self.redis.expire(f"session:{session_id}", self.ttl)
        return session_id
    
    async def get_session(self, session_id: str) -> Optional[dict]:
        data = await self.redis.hgetall(f"session:{session_id}")
        if not data:
            return None
        
        # Update last activity
        await self.redis.hset(f"session:{session_id}", "last_activity", datetime.utcnow().isoformat())
        await self.redis.expire(f"session:{session_id}", self.ttl)
        
        return {k.decode(): v.decode() for k, v in data.items()}
    
    async def delete_session(self, session_id: str):
        await self.redis.delete(f"session:{session_id}")

# MCP Request/Response models
class MCPRequest(BaseModel):
    jsonrpc: str = "2.0"
    method: str
    params: Optional[dict] = None
    id: Optional[int] = None

class MCPResponse(BaseModel):
    jsonrpc: str = "2.0"
    result: Optional[Any] = None
    error: Optional[dict] = None
    id: Optional[int] = None

# Lifespan manager for startup/shutdown
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    app.state.redis = await redis.from_url(
        "redis://redis:6379",
        encoding="utf-8",
        decode_responses=False
    )
    app.state.session_manager = SessionManager(app.state.redis)
    app.state.analyzer = WebEnabledStyleGuideAnalyzer()
    logger.info("MCP HTTP Server started")
    
    yield
    
    # Shutdown
    await app.state.analyzer.close_session()
    await app.state.redis.close()
    logger.info("MCP HTTP Server stopped")

# Create FastAPI app
app = FastAPI(
    title="Microsoft Style Guide MCP Server",
    version="2.0.0",
    docs_url=None,  # Disable in production
    redoc_url=None,
    lifespan=lifespan
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://localhost", "https://vscode.dev", "https://*.visualstudio.com"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Content-Type", "Authorization", "Mcp-Session-Id"],
    expose_headers=["Mcp-Session-Id", "X-Request-Id"],
    max_age=3600
)

# Health check endpoint
@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "mcp-style-guide",
        "version": "2.0.0",
        "transport": "http+sse"
    }

# MCP initialization endpoint
@app.post("/mcp/initialize")
async def initialize_session(request: Request):
    client_info = {
        "user_agent": request.headers.get("user-agent"),
        "client_ip": request.client.host,
        "client_name": request.headers.get("x-mcp-client-name", "unknown")
    }
    
    session_id = await app.state.session_manager.create_session(client_info)
    
    return {
        "jsonrpc": "2.0",
        "result": {
            "protocolVersion": "0.1.0",
            "serverInfo": {
                "name": "microsoft-style-guide",
                "version": "2.0.0",
                "transport": "http+sse"
            },
            "capabilities": {
                "tools": True,
                "resources": False,
                "prompts": True
            },
            "sessionId": session_id
        },
        "id": 1
    }

# Main MCP endpoint
@app.post("/mcp")
async def handle_mcp_request(
    mcp_request: MCPRequest,
    mcp_session_id: Optional[str] = Header(None)
):
    # Validate session
    if mcp_session_id:
        session = await app.state.session_manager.get_session(mcp_session_id)
        if not session:
            raise HTTPException(status_code=401, detail="Invalid or expired session")
    
    try:
        # Route to appropriate handler
        if mcp_request.method == "tools/list":
            result = await handle_tools_list()
        elif mcp_request.method == "tools/call":
            result = await handle_tool_call(mcp_request.params)
        elif mcp_request.method == "prompts/list":
            result = await handle_prompts_list()
        elif mcp_request.method == "prompts/get":
            result = await handle_prompt_get(mcp_request.params)
        else:
            raise ValueError(f"Unknown method: {mcp_request.method}")
        
        return MCPResponse(
            jsonrpc="2.0",
            result=result,
            id=mcp_request.id
        )
    
    except Exception as e:
        logger.error(f"Error handling MCP request: {e}")
        return MCPResponse(
            jsonrpc="2.0",
            error={
                "code": -32603,
                "message": str(e)
            },
            id=mcp_request.id
        )

# Tool handlers
async def handle_tools_list():
    return {
        "tools": [
            {
                "name": "analyze_content",
                "description": "Analyze content against Microsoft Style Guide principles",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "text": {"type": "string"},
                        "analysis_type": {"type": "string", "enum": ["comprehensive", "voice_tone", "grammar", "terminology", "accessibility"]}
                    },
                    "required": ["text"]
                }
            },
            {
                "name": "get_style_guidelines",
                "description": "Get Microsoft Style Guide guidelines for a specific category",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "category": {"type": "string", "enum": ["all", "voice", "grammar", "terminology", "accessibility"]}
                    }
                }
            },
            {
                "name": "suggest_improvements",
                "description": "Get improvement suggestions for content",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "text": {"type": "string"},
                        "focus_area": {"type": "string"}
                    },
                    "required": ["text"]
                }
            },
            {
                "name": "search_style_guide_live",
                "description": "Search Microsoft Style Guide website for live guidance",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "query": {"type": "string"}
                    },
                    "required": ["query"]
                }
            }
        ]
    }

async def handle_tool_call(params: dict):
    tool_name = params.get("name")
    arguments = params.get("arguments", {})
    
    if tool_name == "analyze_content":
        result = await app.state.analyzer.analyze_content(
            arguments["text"],
            arguments.get("analysis_type", "comprehensive")
        )
    elif tool_name == "get_style_guidelines":
        result = app.state.analyzer.get_style_guidelines(
            arguments.get("category", "all")
        )
    elif tool_name == "suggest_improvements":
        result = await app.state.analyzer.suggest_improvements(
            arguments["text"],
            arguments.get("focus_area", "all")
        )
    elif tool_name == "search_style_guide_live":
        result = await app.state.analyzer.search_style_guide_live(
            arguments["query"]
        )
    else:
        raise ValueError(f"Unknown tool: {tool_name}")
    
    return {"content": [{"type": "text", "text": json.dumps(result, indent=2)}]}

# Prompt handlers (if needed)
async def handle_prompts_list():
    return {
        "prompts": [
            {
                "name": "document_reviewer",
                "description": "Comprehensive document review using Microsoft Style Guide"
            }
        ]
    }

async def handle_prompt_get(params: dict):
    prompt_name = params.get("name")
    if prompt_name == "document_reviewer":
        return {
            "prompt": {
                "name": "document_reviewer",
                "description": "Comprehensive document review using Microsoft Style Guide",
                "template": "Review the following document for Microsoft Style Guide compliance:\n\n{document_text}"
            }
        }
    raise ValueError(f"Unknown prompt: {prompt_name}")

# SSE endpoint for streaming responses (future use)
@app.get("/mcp/events")
async def mcp_events(mcp_session_id: Optional[str] = Header(None)):
    if not mcp_session_id:
        raise HTTPException(status_code=401, detail="Session ID required")
    
    session = await app.state.session_manager.get_session(mcp_session_id)
    if not session:
        raise HTTPException(status_code=401, detail="Invalid or expired session")
    
    async def event_generator():
        while True:
            # Send heartbeat
            yield f"event: ping\ndata: {json.dumps({'timestamp': datetime.utcnow().isoformat()})}\n\n"
            await asyncio.sleep(30)
    
    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no"
        }
    )

if __name__ == "__main__":
    uvicorn.run(
        "mcp_http_server:app",
        host="0.0.0.0",
        port=8000,
        log_level="info",
        access_log=True
    )