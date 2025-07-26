#!/usr/bin/env python3
"""
LocalMind V1 - Minimal Demo Version  
Demonstrates the AI assistant architecture without external dependencies
"""
import asyncio
import logging
import sys
import json
from pathlib import Path
from datetime import datetime

# Add project root to Python path
project_root = Path(__file__).parent
sys.path.insert(0, str(project_root))

from localmind.core import AIEngine, ContextManager, RequestProcessor


def setup_logging():
    """Setup basic logging"""
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )


async def demo_ai_assistant():
    """Demonstrate the AI assistant functionality"""
    logger = logging.getLogger(__name__)
    
    print("🤖 LocalMind V1 - Privacy-First AI Assistant Demo")
    print("=" * 60)
    
    try:
        # Initialize components
        print("Initializing AI Assistant...")
        ai_engine = AIEngine()
        context_manager = ContextManager("./demo_data")
        processor = RequestProcessor(ai_engine, context_manager)
        
        # Initialize AI engine
        await ai_engine.initialize()
        print("✓ AI engine initialized")
        
        # Create or get demo user
        user_id = "demo_user"
        profile = context_manager.get_user_profile(user_id)
        if not profile:
            profile = context_manager.create_user_profile(
                user_id=user_id,
                name="Demo User",
                initial_preferences={
                    "communication_style": "friendly",
                    "work_hours": "9:00-17:00"
                }
            )
            print("✓ Created demo user profile")
        else:
            print("✓ Loaded existing demo user profile")
        
        # Demonstrate context switching
        print("\n--- Context Management Demo ---")
        context_manager.switch_mode(user_id, "work", "demo")
        print(f"✓ Switched to work mode")
        
        # Add some work context
        context_manager.update_user_context(user_id, "work", {
            "current_project": "LocalMind Development",
            "meeting_schedule": ["10:00 - Team Standup", "14:00 - Code Review"],
            "tools": ["Python", "FastAPI", "SQLite"]
        })
        print("✓ Updated work context")
        
        # Switch to personal mode
        context_manager.switch_mode(user_id, "personal", "demo")
        context_manager.update_user_context(user_id, "personal", {
            "interests": ["AI", "Privacy", "Open Source"],
            "preferred_music": "Electronic",
            "fitness_goals": "Daily walk"
        })
        print("✓ Switched to personal mode and updated context")
        
        # Demonstrate request processing
        print("\n--- Request Processing Demo ---")
        
        demo_requests = [
            "Switch to work mode and summarize my day",
            "What's my current project status?", 
            "Switch to personal mode",
            "Play some music and remind me about my fitness goals",
            "Help me plan my evening routine"
        ]
        
        for i, request_text in enumerate(demo_requests, 1):
            print(f"\n{i}. User: {request_text}")
            
            response = await processor.process_user_request(
                user_id=user_id,
                text=request_text,
                voice_input=False
            )
            
            print(f"   Assistant: {response.text}")
            
            if response.actions:
                print(f"   Actions ({len(response.actions)}):")
                for action in response.actions:
                    print(f"     - {action.get('type', 'unknown')}: {action}")
            
            if response.requires_confirmation:
                print("   ⚠️  This action requires confirmation")
            
            print(f"   Confidence: {response.confidence:.1%}")
            
            # Small delay for demo effect
            await asyncio.sleep(0.5)
        
        # Demonstrate privacy features
        print("\n--- Privacy & Context Demo ---")
        
        # Get context summary
        summary = await processor.get_context_summary(user_id)
        print("📊 User Context Summary:")
        for key, value in summary.items():
            print(f"   {key}: {value}")
        
        # Get daily summary  
        daily_summary = await processor.get_daily_summary(user_id)
        print("\n📅 Daily Summary:")
        for key, value in daily_summary.items():
            if key != "suggestions":
                print(f"   {key}: {value}")
        
        if daily_summary.get("suggestions"):
            print("   Suggestions:")
            for suggestion in daily_summary["suggestions"]:
                print(f"     - {suggestion}")
        
        # Show request history
        history = processor.get_request_history(user_id, limit=3)
        print(f"\n📜 Recent Request History ({len(history)} items):")
        for req in history:
            timestamp = datetime.fromtimestamp(req["timestamp"])
            print(f"   {timestamp.strftime('%H:%M')} [{req['mode']}]: {req['request'][:40]}...")
        
        print("\n--- Demo Complete ---")
        print("✅ LocalMind V1 demonstrates:")
        print("   • Privacy-first local processing")
        print("   • Work/personal context switching") 
        print("   • Intelligent request processing")
        print("   • Learning and adaptation")
        print("   • Comprehensive privacy controls")
        print("\n🚀 Ready for full implementation with LLM integration!")
        
    except Exception as e:
        logger.error(f"Demo error: {e}")
        print(f"❌ Demo failed: {e}")


async def interactive_demo():
    """Interactive demo mode"""
    print("\n🎯 Interactive Demo Mode")
    print("Type 'exit' to quit, 'help' for commands")
    
    # Initialize components
    ai_engine = AIEngine()
    context_manager = ContextManager("./demo_data")
    processor = RequestProcessor(ai_engine, context_manager)
    
    await ai_engine.initialize()
    
    user_id = "interactive_user"
    profile = context_manager.get_user_profile(user_id)
    if not profile:
        name = input("Enter your name (or press Enter for 'Demo User'): ").strip()
        profile = context_manager.create_user_profile(
            user_id=user_id,
            name=name or "Demo User"
        )
    
    print(f"Hello {profile.name}! Current mode: {context_manager.current_mode}")
    
    while True:
        try:
            user_input = input("\nYou: ").strip()
            
            if user_input.lower() in ['exit', 'quit']:
                break
            elif user_input.lower() == 'help':
                print("""
Available commands:
- exit/quit: Exit the demo
- help: Show this help
- mode work/personal/mixed: Switch mode
- status: Show current status
- summary: Show daily summary
- privacy: Show privacy info
- Or just chat with the AI!
                """)
                continue
            elif user_input.lower().startswith('mode '):
                mode = user_input.split(' ', 1)[1]
                result = await processor.handle_mode_switch(user_id, mode)
                print(f"Assistant: {result}")
                continue
            elif user_input.lower() == 'status':
                summary = await processor.get_context_summary(user_id)
                print(f"Status: {summary}")
                continue
            elif user_input.lower() == 'summary':
                daily = await processor.get_daily_summary(user_id)
                print(f"Daily Summary: {daily}")
                continue
            elif user_input.lower() == 'privacy':
                print("Privacy: All data stored locally, no external connections")
                continue
            
            if not user_input:
                continue
            
            response = await processor.process_user_request(
                user_id=user_id,
                text=user_input,
                voice_input=False
            )
            
            print(f"Assistant: {response.text}")
            
            if response.actions:
                print(f"Actions: {len(response.actions)} planned")
                for i, action in enumerate(response.actions, 1):
                    print(f"  {i}. {action}")
            
        except KeyboardInterrupt:
            break
        except Exception as e:
            print(f"Error: {e}")
    
    print("Goodbye! 👋")


def main():
    """Main entry point"""
    setup_logging()
    
    if len(sys.argv) > 1 and sys.argv[1] == "interactive":
        asyncio.run(interactive_demo())
    else:
        asyncio.run(demo_ai_assistant())


if __name__ == "__main__":
    main()