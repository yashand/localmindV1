"""
Communication Module for LocalMind
Handles voice recognition, text-to-speech, and chat interfaces
"""
import asyncio
import logging
import wave
import tempfile
from typing import Dict, List, Optional, Any, Callable
from pathlib import Path
import json

import speech_recognition as sr
import pyttsx3
import threading
from queue import Queue

logger = logging.getLogger(__name__)


class VoiceRecognizer:
    """Local voice recognition using speech_recognition library"""
    
    def __init__(self, language: str = "en-US"):
        self.recognizer = sr.Recognizer()
        self.microphone = sr.Microphone()
        self.language = language
        self.is_listening = False
        self._setup_microphone()
    
    def _setup_microphone(self):
        """Setup microphone with ambient noise adjustment"""
        try:
            with self.microphone as source:
                logger.info("Adjusting for ambient noise...")
                self.recognizer.adjust_for_ambient_noise(source, duration=1)
            logger.info("Voice recognizer initialized")
        except Exception as e:
            logger.error(f"Failed to setup microphone: {e}")
    
    def listen_once(self, timeout: int = 5) -> Optional[str]:
        """Listen for a single voice command"""
        try:
            with self.microphone as source:
                logger.info("Listening for voice command...")
                audio = self.recognizer.listen(source, timeout=timeout, phrase_time_limit=10)
            
            # Use local speech recognition (offline)
            try:
                text = self.recognizer.recognize_sphinx(audio)
                logger.info(f"Recognized: {text}")
                return text
            except sr.UnknownValueError:
                logger.warning("Could not understand audio")
                return None
            except sr.RequestError as e:
                logger.error(f"Speech recognition error: {e}")
                return None
                
        except sr.WaitTimeoutError:
            logger.warning("Voice input timeout")
            return None
        except Exception as e:
            logger.error(f"Voice recognition error: {e}")
            return None
    
    async def listen_continuously(self, callback: Callable[[str], None], 
                                wake_word: str = "hey localmind") -> None:
        """Listen continuously for wake word and commands"""
        self.is_listening = True
        wake_word_lower = wake_word.lower()
        
        logger.info(f"Starting continuous listening for wake word: '{wake_word}'")
        
        while self.is_listening:
            try:
                text = self.listen_once(timeout=1)
                if text and wake_word_lower in text.lower():
                    logger.info("Wake word detected!")
                    
                    # Listen for the actual command
                    command = self.listen_once(timeout=10)
                    if command:
                        # Remove wake word from command if present
                        command_clean = command.lower().replace(wake_word_lower, "").strip()
                        if command_clean:
                            await asyncio.get_event_loop().run_in_executor(
                                None, callback, command_clean
                            )
                
                await asyncio.sleep(0.1)  # Small delay to prevent excessive CPU usage
                
            except Exception as e:
                logger.error(f"Error in continuous listening: {e}")
                await asyncio.sleep(1)
    
    def stop_listening(self):
        """Stop continuous listening"""
        self.is_listening = False
        logger.info("Stopped continuous listening")


class TextToSpeech:
    """Local text-to-speech using pyttsx3"""
    
    def __init__(self, voice_id: Optional[str] = None, rate: int = 200):
        self.engine = pyttsx3.init()
        self.rate = rate
        self._setup_voice(voice_id)
        self.is_speaking = False
    
    def _setup_voice(self, voice_id: Optional[str]):
        """Setup TTS voice parameters"""
        try:
            # Set speech rate
            self.engine.setProperty('rate', self.rate)
            
            # Set voice if specified
            if voice_id:
                voices = self.engine.getProperty('voices')
                for voice in voices:
                    if voice_id in voice.id:
                        self.engine.setProperty('voice', voice.id)
                        break
            
            logger.info("Text-to-speech initialized")
            
        except Exception as e:
            logger.error(f"Failed to setup TTS: {e}")
    
    def speak(self, text: str, blocking: bool = True) -> None:
        """Speak text aloud"""
        try:
            self.is_speaking = True
            logger.info(f"Speaking: {text[:50]}...")
            
            if blocking:
                self.engine.say(text)
                self.engine.runAndWait()
            else:
                # Non-blocking speech
                def speak_async():
                    self.engine.say(text)
                    self.engine.runAndWait()
                    self.is_speaking = False
                
                thread = threading.Thread(target=speak_async)
                thread.daemon = True
                thread.start()
                return
            
            self.is_speaking = False
            
        except Exception as e:
            logger.error(f"TTS error: {e}")
            self.is_speaking = False
    
    def stop_speaking(self):
        """Stop current speech"""
        try:
            self.engine.stop()
            self.is_speaking = False
        except Exception as e:
            logger.error(f"Error stopping TTS: {e}")
    
    def set_rate(self, rate: int):
        """Set speech rate"""
        self.rate = rate
        self.engine.setProperty('rate', rate)
    
    def get_available_voices(self) -> List[Dict[str, str]]:
        """Get list of available voices"""
        try:
            voices = self.engine.getProperty('voices')
            return [
                {
                    "id": voice.id,
                    "name": voice.name,
                    "age": getattr(voice, 'age', 'unknown'),
                    "gender": getattr(voice, 'gender', 'unknown')
                }
                for voice in voices
            ]
        except Exception as e:
            logger.error(f"Error getting voices: {e}")
            return []


class ChatInterface:
    """Text-based chat interface for the AI assistant"""
    
    def __init__(self):
        self.conversation_history: List[Dict[str, Any]] = []
        self.active_sessions: Dict[str, Dict[str, Any]] = {}
    
    def start_session(self, user_id: str, session_id: str) -> Dict[str, Any]:
        """Start a new chat session"""
        session = {
            "user_id": user_id,
            "session_id": session_id,
            "started_at": asyncio.get_event_loop().time(),
            "messages": [],
            "context": {}
        }
        
        self.active_sessions[session_id] = session
        logger.info(f"Started chat session {session_id} for user {user_id}")
        return session
    
    def add_message(self, session_id: str, message: str, sender: str = "user") -> bool:
        """Add message to chat session"""
        if session_id not in self.active_sessions:
            return False
        
        message_data = {
            "timestamp": asyncio.get_event_loop().time(),
            "sender": sender,
            "message": message
        }
        
        self.active_sessions[session_id]["messages"].append(message_data)
        
        # Keep only recent messages (last 50)
        if len(self.active_sessions[session_id]["messages"]) > 50:
            self.active_sessions[session_id]["messages"] = \
                self.active_sessions[session_id]["messages"][-50:]
        
        return True
    
    def get_session_history(self, session_id: str) -> List[Dict[str, Any]]:
        """Get chat history for session"""
        if session_id not in self.active_sessions:
            return []
        
        return self.active_sessions[session_id]["messages"].copy()
    
    def update_session_context(self, session_id: str, context: Dict[str, Any]):
        """Update session context"""
        if session_id in self.active_sessions:
            self.active_sessions[session_id]["context"].update(context)
    
    def end_session(self, session_id: str) -> bool:
        """End chat session"""
        if session_id in self.active_sessions:
            # Archive session to conversation history
            session = self.active_sessions[session_id]
            session["ended_at"] = asyncio.get_event_loop().time()
            self.conversation_history.append(session)
            
            # Remove from active sessions
            del self.active_sessions[session_id]
            
            logger.info(f"Ended chat session {session_id}")
            return True
        
        return False
    
    def get_user_sessions(self, user_id: str) -> List[Dict[str, Any]]:
        """Get all sessions for a user"""
        user_sessions = []
        
        # Active sessions
        for session in self.active_sessions.values():
            if session["user_id"] == user_id:
                user_sessions.append(session)
        
        # Historical sessions
        for session in self.conversation_history:
            if session["user_id"] == user_id:
                user_sessions.append(session)
        
        return user_sessions


class CommunicationManager:
    """
    Main communication manager that coordinates voice and chat interfaces
    """
    
    def __init__(self, enable_voice: bool = True, enable_tts: bool = True):
        self.voice_recognizer = VoiceRecognizer() if enable_voice else None
        self.text_to_speech = TextToSpeech() if enable_tts else None
        self.chat_interface = ChatInterface()
        
        self.message_callbacks: List[Callable] = []
        self.voice_enabled = enable_voice
        self.tts_enabled = enable_tts
        
        logger.info("Communication manager initialized")
    
    def add_message_callback(self, callback: Callable[[str, str, bool], None]):
        """Add callback for new messages (callback signature: user_id, message, is_voice)"""
        self.message_callbacks.append(callback)
    
    async def start_voice_listening(self, user_id: str, wake_word: str = "hey localmind"):
        """Start continuous voice listening"""
        if not self.voice_recognizer:
            logger.warning("Voice recognition not enabled")
            return
        
        async def voice_callback(command: str):
            logger.info(f"Voice command from {user_id}: {command}")
            
            # Notify all callbacks
            for callback in self.message_callbacks:
                try:
                    await callback(user_id, command, True)
                except Exception as e:
                    logger.error(f"Error in message callback: {e}")
        
        await self.voice_recognizer.listen_continuously(voice_callback, wake_word)
    
    def stop_voice_listening(self):
        """Stop voice listening"""
        if self.voice_recognizer:
            self.voice_recognizer.stop_listening()
    
    def process_text_message(self, user_id: str, message: str, session_id: str) -> bool:
        """Process text message from user"""
        try:
            # Add to chat session
            if session_id not in self.chat_interface.active_sessions:
                self.chat_interface.start_session(user_id, session_id)
            
            self.chat_interface.add_message(session_id, message, "user")
            
            # Notify callbacks
            for callback in self.message_callbacks:
                try:
                    asyncio.create_task(callback(user_id, message, False))
                except Exception as e:
                    logger.error(f"Error in message callback: {e}")
            
            return True
            
        except Exception as e:
            logger.error(f"Error processing text message: {e}")
            return False
    
    def send_response(self, user_id: str, response: str, session_id: str, 
                     speak_aloud: bool = False) -> bool:
        """Send response to user"""
        try:
            # Add to chat session
            if session_id in self.chat_interface.active_sessions:
                self.chat_interface.add_message(session_id, response, "assistant")
            
            # Speak response if requested and TTS is enabled
            if speak_aloud and self.text_to_speech:
                self.text_to_speech.speak(response, blocking=False)
            
            logger.info(f"Sent response to {user_id}: {response[:50]}...")
            return True
            
        except Exception as e:
            logger.error(f"Error sending response: {e}")
            return False
    
    def get_session_status(self) -> Dict[str, Any]:
        """Get communication session status"""
        return {
            "voice_enabled": self.voice_enabled,
            "tts_enabled": self.tts_enabled,
            "voice_listening": self.voice_recognizer.is_listening if self.voice_recognizer else False,
            "tts_speaking": self.text_to_speech.is_speaking if self.text_to_speech else False,
            "active_chat_sessions": len(self.chat_interface.active_sessions),
            "total_conversation_history": len(self.chat_interface.conversation_history)
        }
    
    def configure_voice_settings(self, settings: Dict[str, Any]) -> bool:
        """Configure voice recognition and TTS settings"""
        try:
            if "tts_rate" in settings and self.text_to_speech:
                self.text_to_speech.set_rate(settings["tts_rate"])
            
            if "language" in settings and self.voice_recognizer:
                self.voice_recognizer.language = settings["language"]
            
            logger.info("Voice settings updated")
            return True
            
        except Exception as e:
            logger.error(f"Error configuring voice settings: {e}")
            return False