#!/usr/bin/env python3
"""
Basic tests for LocalMind V1
"""
import pytest
import asyncio
import tempfile
import os
from pathlib import Path

# Add project root to path
import sys
sys.path.insert(0, str(Path(__file__).parent))

from localmind.core import AIEngine, ContextManager, RequestProcessor, ProcessingMode
from localmind.privacy import PrivacyManager, PrivacySettings
from localmind.communication import CommunicationManager


class TestAIEngine:
    """Test AI engine functionality"""
    
    @pytest.mark.asyncio
    async def test_engine_initialization(self):
        """Test AI engine can be initialized"""
        engine = AIEngine()
        assert not engine._initialized
        
        # Initialize should work (mock implementation)
        result = await engine.initialize()
        assert result is True
        assert engine._initialized
    
    @pytest.mark.asyncio
    async def test_process_request(self):
        """Test request processing"""
        engine = AIEngine()
        await engine.initialize()
        
        from localmind.core.engine import AIRequest
        
        request = AIRequest(
            text="Hello AI",
            mode=ProcessingMode.PERSONAL,
            context={},
            user_id="test_user",
            timestamp=1234567890.0
        )
        
        response = await engine.process_request(request)
        assert response.text
        assert isinstance(response.actions, list)
        assert isinstance(response.confidence, float)


class TestContextManager:
    """Test context manager functionality"""
    
    def test_context_manager_init(self):
        """Test context manager initialization"""
        with tempfile.TemporaryDirectory() as temp_dir:
            manager = ContextManager(temp_dir)
            assert manager.data_dir.exists()
            assert manager.db_path.exists()
    
    def test_user_profile_creation(self):
        """Test user profile creation"""
        with tempfile.TemporaryDirectory() as temp_dir:
            manager = ContextManager(temp_dir)
            
            profile = manager.create_user_profile("test_user", "Test User")
            assert profile.user_id == "test_user"
            assert profile.name == "Test User"
            
            # Should be able to retrieve it
            retrieved = manager.get_user_profile("test_user")
            assert retrieved is not None
            assert retrieved.user_id == "test_user"
    
    def test_context_switching(self):
        """Test work/personal mode switching"""
        with tempfile.TemporaryDirectory() as temp_dir:
            manager = ContextManager(temp_dir)
            
            manager.switch_mode("test_user", "work", "test")
            assert manager.current_mode == "work"
            
            manager.switch_mode("test_user", "personal", "test")
            assert manager.current_mode == "personal"


class TestPrivacyManager:
    """Test privacy manager functionality"""
    
    def test_privacy_manager_init(self):
        """Test privacy manager initialization"""
        with tempfile.TemporaryDirectory() as temp_dir:
            manager = PrivacyManager(temp_dir)
            assert manager.data_dir.exists()
            assert manager.db_path.exists()
    
    def test_privacy_settings(self):
        """Test privacy settings creation and retrieval"""
        with tempfile.TemporaryDirectory() as temp_dir:
            manager = PrivacyManager(temp_dir)
            
            settings = manager.create_privacy_settings("test_user")
            assert settings.user_id == "test_user"
            assert settings.data_retention_days == 90
            assert settings.encryption_enabled is True
            
            # Should be able to retrieve it
            retrieved = manager.get_privacy_settings("test_user")
            assert retrieved is not None
            assert retrieved.user_id == "test_user"
    
    def test_data_access_logging(self):
        """Test data access logging"""
        with tempfile.TemporaryDirectory() as temp_dir:
            manager = PrivacyManager(temp_dir)
            
            manager.log_data_access("test_user", "contacts", "user_request", "core")
            
            logs = manager.get_access_logs("test_user", days=1)
            assert len(logs) == 1
            assert logs[0].data_type == "contacts"


class TestCommunicationManager:
    """Test communication manager functionality"""
    
    def test_communication_manager_init(self):
        """Test communication manager initialization"""
        manager = CommunicationManager(enable_voice=False, enable_tts=False)
        assert manager.voice_recognizer is None
        assert manager.text_to_speech is None
        assert manager.chat_interface is not None
    
    def test_chat_interface(self):
        """Test chat interface functionality"""
        manager = CommunicationManager(enable_voice=False, enable_tts=False)
        
        session = manager.chat_interface.start_session("test_user", "test_session")
        assert session["user_id"] == "test_user"
        assert session["session_id"] == "test_session"
        
        success = manager.chat_interface.add_message("test_session", "Hello", "user")
        assert success is True
        
        history = manager.chat_interface.get_session_history("test_session")
        assert len(history) == 1
        assert history[0]["message"] == "Hello"


@pytest.mark.asyncio
async def test_full_integration():
    """Test full integration of core components"""
    with tempfile.TemporaryDirectory() as temp_dir:
        # Initialize components
        ai_engine = AIEngine()
        context_manager = ContextManager(temp_dir)
        processor = RequestProcessor(ai_engine, context_manager)
        
        # Initialize AI engine
        await ai_engine.initialize()
        
        # Create user profile
        profile = context_manager.create_user_profile("test_user", "Test User")
        
        # Process a request
        response = await processor.process_user_request(
            user_id="test_user",
            text="Hello AI assistant",
            voice_input=False
        )
        
        assert response.text
        assert isinstance(response.actions, list)
        assert isinstance(response.confidence, float)
        
        # Check that context was updated
        summary = await processor.get_context_summary("test_user")
        assert summary["user_name"] == "Test User"


if __name__ == "__main__":
    # Run tests
    pytest.main([__file__, "-v"])