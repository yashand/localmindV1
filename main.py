#!/usr/bin/env python3
"""
LocalMind V1 - Main Entry Point
Privacy-first AI assistant with local processing
"""
import asyncio
import logging
import sys
import argparse
from pathlib import Path

# Add project root to Python path
project_root = Path(__file__).parent
sys.path.insert(0, str(project_root))

from localmind.desktop import create_server
from localmind.core import AIEngine, ContextManager, RequestProcessor
from localmind.privacy import PrivacyManager
from localmind.communication import CommunicationManager


def setup_logging(level: str = "INFO"):
    """Setup logging configuration"""
    logging.basicConfig(
        level=getattr(logging, level.upper()),
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.StreamHandler(sys.stdout),
            logging.FileHandler('localmind.log')
        ]
    )


async def run_server(args):
    """Run the LocalMind server"""
    logger = logging.getLogger(__name__)
    
    try:
        logger.info("Starting LocalMind AI Assistant...")
        
        # Create and initialize server
        server = await create_server(
            data_dir=args.data_dir,
            model_path=args.model_path
        )
        
        logger.info(f"Server initialized, starting on port {args.port}")
        
        # Start server
        import uvicorn
        config = uvicorn.Config(
            app=server.app,
            host=args.host,
            port=args.port,
            log_level=args.log_level.lower()
        )
        
        server_instance = uvicorn.Server(config)
        await server_instance.serve()
        
    except KeyboardInterrupt:
        logger.info("Shutting down LocalMind server...")
    except Exception as e:
        logger.error(f"Server error: {e}")
        sys.exit(1)


async def run_cli(args):
    """Run LocalMind in CLI mode"""
    logger = logging.getLogger(__name__)
    
    try:
        logger.info("Starting LocalMind CLI...")
        
        # Initialize components
        ai_engine = AIEngine(args.model_path)
        context_manager = ContextManager(args.data_dir)
        processor = RequestProcessor(ai_engine, context_manager)
        comm_manager = CommunicationManager(enable_voice=args.voice, enable_tts=args.tts)
        
        # Initialize AI engine
        await ai_engine.initialize()
        
        # Setup user
        user_id = "cli_user"
        profile = context_manager.get_user_profile(user_id)
        if not profile:
            profile = context_manager.create_user_profile(user_id, "CLI User")
            logger.info("Created new user profile for CLI")
        
        logger.info("LocalMind CLI ready! Type 'exit' to quit, 'help' for commands.")
        
        while True:
            try:
                # Get user input
                user_input = input("\nYou: ").strip()
                
                if user_input.lower() in ['exit', 'quit']:
                    break
                elif user_input.lower() == 'help':
                    print("""
Available commands:
- exit/quit: Exit the application
- help: Show this help message
- mode work/personal/mixed: Switch processing mode
- privacy: Show privacy report
- status: Show system status
- Or just type any request for the AI assistant
                    """)
                    continue
                elif user_input.lower().startswith('mode '):
                    mode = user_input.split(' ', 1)[1]
                    result = await processor.handle_mode_switch(user_id, mode)
                    print(f"Assistant: {result}")
                    continue
                elif user_input.lower() == 'privacy':
                    privacy_manager = PrivacyManager(args.data_dir)
                    report = privacy_manager.generate_privacy_report(user_id)
                    print(f"Privacy Report: {report}")
                    continue
                elif user_input.lower() == 'status':
                    status = ai_engine.get_status()
                    context_summary = await processor.get_context_summary(user_id)
                    print(f"AI Engine: {status}")
                    print(f"Context: {context_summary}")
                    continue
                
                if not user_input:
                    continue
                
                # Process request
                response = await processor.process_user_request(
                    user_id=user_id,
                    text=user_input,
                    voice_input=False
                )
                
                # Show response
                print(f"Assistant: {response.text}")
                
                if response.actions:
                    print(f"Actions to perform: {len(response.actions)}")
                    for i, action in enumerate(response.actions, 1):
                        print(f"  {i}. {action}")
                
                if response.requires_confirmation:
                    confirm = input("Confirm action? (y/n): ").strip().lower()
                    if confirm != 'y':
                        print("Action cancelled.")
                
            except KeyboardInterrupt:
                break
            except Exception as e:
                logger.error(f"CLI error: {e}")
                print(f"Error: {e}")
        
        logger.info("LocalMind CLI shutting down...")
        
    except Exception as e:
        logger.error(f"CLI error: {e}")
        sys.exit(1)


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description="LocalMind V1 - Privacy-First AI Assistant")
    
    parser.add_argument(
        "mode", 
        choices=["server", "cli"],
        help="Run mode: server (web API) or cli (command line)"
    )
    
    parser.add_argument(
        "--data-dir",
        default="./data",
        help="Data directory for storing user data (default: ./data)"
    )
    
    parser.add_argument(
        "--model-path",
        help="Path to local LLM model (optional)"
    )
    
    parser.add_argument(
        "--host",
        default="0.0.0.0",
        help="Server host (default: 0.0.0.0)"
    )
    
    parser.add_argument(
        "--port",
        type=int,
        default=8000,
        help="Server port (default: 8000)"
    )
    
    parser.add_argument(
        "--log-level",
        choices=["DEBUG", "INFO", "WARNING", "ERROR"],
        default="INFO",
        help="Logging level (default: INFO)"
    )
    
    parser.add_argument(
        "--voice",
        action="store_true",
        help="Enable voice recognition in CLI mode"
    )
    
    parser.add_argument(
        "--tts",
        action="store_true", 
        help="Enable text-to-speech in CLI mode"
    )
    
    args = parser.parse_args()
    
    # Setup logging
    setup_logging(args.log_level)
    
    # Create data directory
    Path(args.data_dir).mkdir(exist_ok=True)
    
    # Run appropriate mode
    if args.mode == "server":
        asyncio.run(run_server(args))
    elif args.mode == "cli":
        asyncio.run(run_cli(args))


if __name__ == "__main__":
    main()