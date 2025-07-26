"""
Communication Module for LocalMind
Voice recognition, text-to-speech, and chat interfaces
"""

from .manager import (
    VoiceRecognizer, 
    TextToSpeech, 
    ChatInterface, 
    CommunicationManager
)

__all__ = [
    "VoiceRecognizer", 
    "TextToSpeech", 
    "ChatInterface", 
    "CommunicationManager"
]