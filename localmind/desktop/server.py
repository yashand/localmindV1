"""
Desktop Server for LocalMind
FastAPI server that hosts the AI assistant and provides API endpoints
"""
import asyncio
import logging
from typing import Dict, List, Optional, Any
from datetime import datetime
from pathlib import Path

from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse
from pydantic import BaseModel

from ..core import AIEngine, ContextManager, RequestProcessor

logger = logging.getLogger(__name__)


class ChatRequest(BaseModel):
    """Chat request model"""
    user_id: str
    message: str
    voice_input: bool = False
    context: Optional[Dict[str, Any]] = None


class ChatResponse(BaseModel):
    """Chat response model"""
    response: str
    actions: List[Dict[str, Any]]
    requires_confirmation: bool
    confidence: float


class ModeSwitch(BaseModel):
    """Mode switch request"""
    user_id: str
    mode: str


class LocalMindServer:
    """
    Desktop server for LocalMind AI assistant
    Provides REST API and WebSocket interfaces for mobile clients
    """
    
    def __init__(self, data_dir: str = "./data", model_path: Optional[str] = None):
        self.app = FastAPI(
            title="LocalMind AI Assistant",
            description="Privacy-first AI assistant with local processing",
            version="1.0.0"
        )
        
        # Initialize core components
        self.ai_engine = AIEngine(model_path)
        self.context_manager = ContextManager(data_dir)
        self.request_processor = RequestProcessor(self.ai_engine, self.context_manager)
        
        # WebSocket connections
        self.active_connections: Dict[str, WebSocket] = {}
        
        # Setup routes and middleware
        self._setup_middleware()
        self._setup_routes()
        self._setup_websockets()
        
    def _setup_middleware(self):
        """Setup CORS and other middleware"""
        self.app.add_middleware(
            CORSMiddleware,
            allow_origins=["*"],  # In production, restrict to your devices
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["*"],
        )
        
    def _setup_routes(self):
        """Setup REST API routes"""
        
        @self.app.get("/")
        async def root():
            return {"message": "LocalMind AI Assistant", "status": "running"}
        
        @self.app.get("/health")
        async def health_check():
            """Health check endpoint"""
            ai_status = self.ai_engine.get_status()
            return {
                "status": "healthy",
                "timestamp": datetime.now().isoformat(),
                "ai_engine": ai_status,
                "active_connections": len(self.active_connections)
            }
        
        @self.app.post("/chat", response_model=ChatResponse)
        async def chat(request: ChatRequest):
            """Process chat request"""
            try:
                response = await self.request_processor.process_user_request(
                    user_id=request.user_id,
                    text=request.message,
                    voice_input=request.voice_input,
                    additional_context=request.context
                )
                
                return ChatResponse(
                    response=response.text,
                    actions=response.actions,
                    requires_confirmation=response.requires_confirmation,
                    confidence=response.confidence
                )
                
            except Exception as e:
                logger.error(f"Chat error: {e}")
                raise HTTPException(status_code=500, detail=str(e))
        
        @self.app.post("/mode")
        async def switch_mode(request: ModeSwitch):
            """Switch processing mode"""
            try:
                result = await self.request_processor.handle_mode_switch(
                    request.user_id, 
                    request.mode
                )
                return {"message": result}
                
            except Exception as e:
                logger.error(f"Mode switch error: {e}")
                raise HTTPException(status_code=500, detail=str(e))
        
        @self.app.get("/context/{user_id}")
        async def get_context(user_id: str):
            """Get user context summary"""
            try:
                summary = await self.request_processor.get_context_summary(user_id)
                return summary
                
            except Exception as e:
                logger.error(f"Context error: {e}")
                raise HTTPException(status_code=500, detail=str(e))
        
        @self.app.get("/privacy/{user_id}")
        async def privacy_report(user_id: str):
            """Get privacy report for user"""
            try:
                report = self.context_manager.get_privacy_report(user_id)
                return report
                
            except Exception as e:
                logger.error(f"Privacy report error: {e}")
                raise HTTPException(status_code=500, detail=str(e))
        
        @self.app.get("/summary/{user_id}")
        async def daily_summary(user_id: str):
            """Get daily activity summary"""
            try:
                summary = await self.request_processor.get_daily_summary(user_id)
                return summary
                
            except Exception as e:
                logger.error(f"Summary error: {e}")
                raise HTTPException(status_code=500, detail=str(e))
        
        @self.app.get("/history/{user_id}")
        async def request_history(user_id: str, limit: int = 10):
            """Get request history for user"""
            try:
                history = self.request_processor.get_request_history(user_id, limit)
                return {"history": history}
                
            except Exception as e:
                logger.error(f"History error: {e}")
                raise HTTPException(status_code=500, detail=str(e))
        
        @self.app.delete("/user/{user_id}")
        async def delete_user_data(user_id: str):
            """Delete all user data (privacy compliance)"""
            try:
                success = self.request_processor.clear_user_data(user_id)
                if success:
                    return {"message": f"All data deleted for user {user_id}"}
                else:
                    raise HTTPException(status_code=500, detail="Failed to delete user data")
                    
            except Exception as e:
                logger.error(f"Delete user error: {e}")
                raise HTTPException(status_code=500, detail=str(e))
    
    def _setup_websockets(self):
        """Setup WebSocket connections for real-time communication"""
        
        @self.app.websocket("/ws/{user_id}")
        async def websocket_endpoint(websocket: WebSocket, user_id: str):
            await websocket.accept()
            self.active_connections[user_id] = websocket
            logger.info(f"WebSocket connected for user {user_id}")
            
            try:
                while True:
                    # Receive message from client
                    data = await websocket.receive_json()
                    
                    # Process the request
                    response = await self.request_processor.process_user_request(
                        user_id=user_id,
                        text=data.get("message", ""),
                        voice_input=data.get("voice_input", False),
                        additional_context=data.get("context")
                    )
                    
                    # Send response back
                    await websocket.send_json({
                        "type": "response",
                        "response": response.text,
                        "actions": response.actions,
                        "requires_confirmation": response.requires_confirmation,
                        "confidence": response.confidence,
                        "timestamp": datetime.now().isoformat()
                    })
                    
            except WebSocketDisconnect:
                del self.active_connections[user_id]
                logger.info(f"WebSocket disconnected for user {user_id}")
            except Exception as e:
                logger.error(f"WebSocket error for user {user_id}: {e}")
                if user_id in self.active_connections:
                    del self.active_connections[user_id]
    
    async def initialize(self):
        """Initialize the server and AI engine"""
        logger.info("Initializing LocalMind server...")
        
        # Initialize AI engine
        success = await self.ai_engine.initialize()
        if not success:
            raise RuntimeError("Failed to initialize AI engine")
        
        logger.info("LocalMind server initialized successfully")
    
    async def broadcast_to_user(self, user_id: str, message: Dict[str, Any]):
        """Send message to specific user via WebSocket"""
        if user_id in self.active_connections:
            try:
                await self.active_connections[user_id].send_json(message)
            except Exception as e:
                logger.error(f"Failed to send message to user {user_id}: {e}")
                # Remove stale connection
                del self.active_connections[user_id]
    
    async def broadcast_to_all(self, message: Dict[str, Any]):
        """Broadcast message to all connected users"""
        disconnected = []
        
        for user_id, websocket in self.active_connections.items():
            try:
                await websocket.send_json(message)
            except Exception as e:
                logger.error(f"Failed to broadcast to user {user_id}: {e}")
                disconnected.append(user_id)
        
        # Clean up disconnected connections
        for user_id in disconnected:
            del self.active_connections[user_id]
    
    def get_server_stats(self) -> Dict[str, Any]:
        """Get server statistics"""
        return {
            "active_connections": len(self.active_connections),
            "connected_users": list(self.active_connections.keys()),
            "ai_engine_status": self.ai_engine.get_status(),
            "uptime": datetime.now().isoformat()
        }


async def create_server(data_dir: str = "./data", model_path: Optional[str] = None) -> LocalMindServer:
    """Factory function to create and initialize server"""
    server = LocalMindServer(data_dir, model_path)
    await server.initialize()
    return server


if __name__ == "__main__":
    import uvicorn
    import sys
    import os
    
    # Setup logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    # Create server instance
    async def main():
        server = await create_server()
        
        # Run server
        config = uvicorn.Config(
            app=server.app,
            host="0.0.0.0",
            port=8000,
            log_level="info"
        )
        
        server_instance = uvicorn.Server(config)
        await server_instance.serve()
    
    # Run the server
    asyncio.run(main())