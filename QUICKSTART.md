# LocalMind V1 - Quick Start Guide

## Installation & Setup

### 1. Clone and Setup
```bash
git clone https://github.com/yashand/localmindV1.git
cd localmindV1
```

### 2. Run Demo (No Dependencies Required)
```bash
python demo.py
```

### 3. Interactive Demo
```bash
python demo.py interactive
```

### 4. For Full Installation
```bash
pip install -r requirements.txt
python setup.py
```

## Quick Examples

### Basic Usage
```python
from localmind.core import AIEngine, ContextManager, RequestProcessor
import asyncio

async def main():
    # Initialize
    ai_engine = AIEngine()
    context_manager = ContextManager("./data")
    processor = RequestProcessor(ai_engine, context_manager)
    
    await ai_engine.initialize()
    
    # Process request
    response = await processor.process_user_request(
        user_id="user123",
        text="Switch to work mode and summarize my tasks",
        voice_input=False
    )
    
    print(f"Response: {response.text}")

asyncio.run(main())
```

### Server Mode
```bash
python main.py server --port 8000
```

Then visit:
- API: `http://localhost:8000`
- Health: `http://localhost:8000/health`
- Privacy: `http://localhost:8000/privacy/user123`

### CLI Mode
```bash
python main.py cli --voice --tts
```

## Key Features Demonstrated

### 1. Privacy-First Design
- ✅ All data stored locally
- ✅ No external API calls
- ✅ Encrypted data storage
- ✅ Granular privacy controls

### 2. Context Intelligence
- ✅ Work/Personal mode switching
- ✅ Automatic context detection
- ✅ Learning from interactions
- ✅ Smart routine suggestions

### 3. Local Processing
- ✅ Ready for LLM integration
- ✅ Voice recognition framework
- ✅ Text-to-speech support
- ✅ Cross-device architecture

### 4. Extensible Architecture
- ✅ Plugin system ready
- ✅ Modular components
- ✅ REST API & WebSocket
- ✅ Mobile integration ready

## Architecture Overview

```
LocalMind V1
├── Core AI Engine          # LLM processing & decision making
├── Context Manager         # Work/personal modes & learning
├── Privacy Manager         # Data protection & encryption
├── Communication Layer     # Voice, chat, TTS interfaces
├── Desktop Server          # REST API & WebSocket server
├── Mobile Integration      # App automation & device control
├── Automation Engine       # Smart routines & triggers
└── Plugin System          # Extensible functionality
```

## Next Steps

1. **Integrate Real LLM**: Add Ollama/llama.cpp for actual AI processing
2. **Mobile Apps**: Build Android/iOS companion apps
3. **Voice Processing**: Integrate Whisper for offline speech recognition
4. **Automation**: Expand device and app control capabilities
5. **UI Dashboard**: Create web interface for management
6. **Cross-Device**: Implement secure device synchronization

## Demo Commands

Try these in interactive mode:
- `mode work` - Switch to work context
- `mode personal` - Switch to personal context  
- `status` - Show current status
- `summary` - Show daily activity summary
- `privacy` - Show privacy information
- Any natural language request!

## Privacy Commitment

LocalMind V1 is built with privacy as the foundation:
- 🔒 **Local-Only Processing**: No data leaves your devices
- 🔑 **Encryption**: All stored data is encrypted
- 👁️ **Transparency**: Full visibility into data access
- ⚙️ **Control**: Granular privacy settings
- 🗑️ **Deletion**: Easy data removal and reset
- 📊 **Auditing**: Complete access logs and reports

---

**Ready to experience privacy-first AI assistance!** 🚀