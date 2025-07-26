#!/usr/bin/env python3
"""
Example: Basic AI Assistant Usage
Demonstrates core functionality of LocalMind V1
"""
import asyncio
import logging
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from localmind.core import AIEngine, ContextManager, RequestProcessor

# Setup logging
logging.basicConfig(level=logging.INFO)

async def basic_example():
    """Basic AI assistant example"""
    print("🤖 LocalMind V1 - Basic Example")
    print("=" * 40)
    
    # Initialize components
    ai_engine = AIEngine()
    context_manager = ContextManager("./example_data")
    processor = RequestProcessor(ai_engine, context_manager)
    
    # Initialize AI engine
    await ai_engine.initialize()
    print("✓ AI Assistant initialized")
    
    # Create user
    user_id = "example_user"
    profile = context_manager.create_user_profile(user_id, "Example User")
    print(f"✓ Created user: {profile.name}")
    
    # Process some requests
    requests = [
        "Good morning! What's on my schedule today?",
        "Switch to work mode",
        "Help me focus on my current project",
        "Switch to personal mode", 
        "Remind me to take a break"
    ]
    
    for request in requests:
        print(f"\n👤 User: {request}")
        
        response = await processor.process_user_request(
            user_id=user_id,
            text=request,
            voice_input=False
        )
        
        print(f"🤖 Assistant: {response.text}")
        if response.actions:
            print(f"📋 Actions: {len(response.actions)} planned")
    
    # Show summary
    summary = await processor.get_context_summary(user_id)
    print(f"\n📊 Summary: {summary}")

if __name__ == "__main__":
    asyncio.run(basic_example())