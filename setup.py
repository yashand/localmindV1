#!/usr/bin/env python3
"""
Setup script for LocalMind V1
Handles initial configuration and setup
"""
import os
import sys
from pathlib import Path
import json
import getpass

def create_config():
    """Create initial configuration"""
    config = {
        "version": "1.0.0",
        "data_dir": "./data",
        "server": {
            "host": "0.0.0.0",
            "port": 8000,
            "cors_origins": ["*"]
        },
        "ai": {
            "model_type": "local",
            "model_path": None,
            "temperature": 0.7,
            "max_tokens": 512
        },
        "privacy": {
            "encryption_enabled": True,
            "default_retention_days": 90,
            "auto_delete_enabled": True
        },
        "communication": {
            "voice_enabled": True,
            "tts_enabled": True,
            "wake_word": "hey localmind",
            "language": "en-US"
        },
        "features": {
            "work_personal_modes": True,
            "learning_enabled": True,
            "cross_device_sync": True,
            "automation_enabled": True
        }
    }
    
    return config

def setup_directories():
    """Create necessary directories"""
    directories = [
        "data",
        "data/users",
        "data/models", 
        "data/logs",
        "data/backups"
    ]
    
    for directory in directories:
        Path(directory).mkdir(parents=True, exist_ok=True)
        print(f"✓ Created directory: {directory}")

def create_default_user():
    """Create default user profile"""
    from localmind.core import ContextManager
    from localmind.privacy import PrivacyManager
    
    context_manager = ContextManager("./data")
    privacy_manager = PrivacyManager("./data")
    
    # Get user details
    print("\n=== Creating Default User Profile ===")
    name = input("Enter your name: ").strip() or "User"
    user_id = "main_user"
    
    # Create user profile
    profile = context_manager.create_user_profile(
        user_id=user_id,
        name=name,
        initial_preferences={
            "timezone": "UTC",
            "language": "en",
            "communication_style": "professional"
        }
    )
    
    # Create privacy settings
    privacy_settings = privacy_manager.create_privacy_settings(user_id)
    
    print(f"✓ Created user profile for: {name}")
    print(f"✓ User ID: {user_id}")
    print(f"✓ Privacy settings configured")
    
    return user_id

def check_dependencies():
    """Check if required dependencies are installed"""
    required_packages = [
        "fastapi",
        "uvicorn", 
        "speech_recognition",
        "pyttsx3",
        "cryptography",
        "sqlite3"
    ]
    
    missing_packages = []
    
    for package in required_packages:
        try:
            __import__(package)
            print(f"✓ {package}")
        except ImportError:
            missing_packages.append(package)
            print(f"✗ {package} (missing)")
    
    if missing_packages:
        print(f"\nMissing packages: {', '.join(missing_packages)}")
        print("Install with: pip install -r requirements.txt")
        return False
    
    return True

def test_basic_functionality():
    """Test basic system functionality"""
    print("\n=== Testing Basic Functionality ===")
    
    try:
        from localmind.core import AIEngine, ContextManager
        from localmind.privacy import PrivacyManager
        
        # Test AI engine
        ai_engine = AIEngine()
        print("✓ AI engine can be created")
        
        # Test context manager
        context_manager = ContextManager("./data")
        print("✓ Context manager initialized")
        
        # Test privacy manager
        privacy_manager = PrivacyManager("./data")
        print("✓ Privacy manager initialized")
        
        print("✓ All core components working")
        return True
        
    except Exception as e:
        print(f"✗ Error testing functionality: {e}")
        return False

def create_example_files():
    """Create example configuration and usage files"""
    
    # Example automation rule
    example_automation = {
        "name": "Morning Routine",
        "trigger": {
            "type": "time",
            "value": "08:00"
        },
        "conditions": {
            "weekdays_only": True
        },
        "actions": [
            {
                "type": "mode_switch",
                "mode": "work"
            },
            {
                "type": "notification",
                "message": "Good morning! Switching to work mode."
            }
        ]
    }
    
    with open("examples/automation_rule.json", "w") as f:
        json.dump(example_automation, f, indent=2)
    
    # Example usage script
    usage_script = '''#!/usr/bin/env python3
"""
Example usage of LocalMind V1
"""
import asyncio
from localmind.core import AIEngine, ContextManager, RequestProcessor

async def main():
    # Initialize components
    ai_engine = AIEngine()
    context_manager = ContextManager("./data")
    processor = RequestProcessor(ai_engine, context_manager)
    
    # Initialize AI engine
    await ai_engine.initialize()
    
    # Process a request
    response = await processor.process_user_request(
        user_id="main_user",
        text="What's the weather like?",
        voice_input=False
    )
    
    print(f"Response: {response.text}")
    print(f"Actions: {response.actions}")

if __name__ == "__main__":
    asyncio.run(main())
'''
    
    Path("examples").mkdir(exist_ok=True)
    with open("examples/usage_example.py", "w") as f:
        f.write(usage_script)
    
    print("✓ Created example files in examples/ directory")

def main():
    """Main setup function"""
    print("🤖 LocalMind V1 Setup")
    print("=" * 50)
    
    # Check Python version
    if sys.version_info < (3, 9):
        print("❌ Python 3.9+ required")
        sys.exit(1)
    
    print("✓ Python version OK")
    
    # Check dependencies
    print("\n=== Checking Dependencies ===")
    if not check_dependencies():
        print("\n❌ Please install missing dependencies first")
        sys.exit(1)
    
    # Setup directories
    print("\n=== Setting Up Directories ===")
    setup_directories()
    
    # Create configuration
    print("\n=== Creating Configuration ===")
    config = create_config()
    
    with open("config.json", "w") as f:
        json.dump(config, f, indent=2)
    
    print("✓ Created config.json")
    
    # Create default user
    try:
        user_id = create_default_user()
    except Exception as e:
        print(f"⚠️  Could not create default user: {e}")
        print("You can create a user later when running the application")
        user_id = None
    
    # Test functionality
    if test_basic_functionality():
        print("✓ Basic functionality test passed")
    else:
        print("⚠️  Some functionality tests failed")
    
    # Create examples
    print("\n=== Creating Examples ===")
    create_example_files()
    
    # Final instructions
    print("\n" + "=" * 50)
    print("🎉 Setup Complete!")
    print("\nNext steps:")
    print("1. Start the server: python main.py server")
    print("2. Or try CLI mode: python main.py cli")
    print("3. Access web interface: http://localhost:8000")
    print("4. Check privacy dashboard: http://localhost:8000/privacy")
    
    if user_id:
        print(f"\nDefault user ID: {user_id}")
    
    print("\nFor help: python main.py --help")
    print("\nEnjoy your privacy-first AI assistant! 🚀")

if __name__ == "__main__":
    main()