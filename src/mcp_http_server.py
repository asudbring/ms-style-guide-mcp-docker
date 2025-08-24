import asyncio
import json
import logging
from typing import Dict, Optional, Any
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, Response, HTTPException
from fastapi.responses import StreamingResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn

from style_analyzer import WebEnabledStyleGuideAnalyzer

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

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
    app.state.analyzer = WebEnabledStyleGuideAnalyzer()
    logger.info("MCP HTTP Server started (stateless mode)")
    
    yield
    
    # Shutdown
    await app.state.analyzer.close_session()
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

# Main MCP endpoint - stateless, handles all MCP methods
@app.post("/mcp")
async def handle_mcp_request(
    mcp_request: MCPRequest
):
    # Stateless MCP server - no session management needed
    try:
        # Route to appropriate handler
        if mcp_request.method == "initialize":
            result = await handle_initialize(mcp_request.params)
        elif mcp_request.method == "tools/list":
            result = await handle_tools_list()
        elif mcp_request.method == "tools/call":
            if mcp_request.params is None:
                raise ValueError("tools/call requires params")
            result = await handle_tool_call(mcp_request.params)
        elif mcp_request.method == "prompts/list":
            result = await handle_prompts_list()
        elif mcp_request.method == "prompts/get":
            if mcp_request.params is None:
                raise ValueError("prompts/get requires params")
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
async def handle_initialize(params: Optional[dict] = None):
    """Handle initialize method within the MCP endpoint"""
    return {
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
        }
        # Note: Not including sessionId for VS Code compatibility
    }

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

if __name__ == "__main__":
    uvicorn.run(
        "mcp_http_server:app",
        host="0.0.0.0",
        port=8000,
        log_level="info",
        access_log=True
    )