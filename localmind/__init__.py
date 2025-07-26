"""
LocalMind V1 - Privacy-First AI Assistant
Core module for AI processing and orchestration
"""

__version__ = "1.0.0"
__author__ = "LocalMind Team"
__description__ = "Privacy-first AI assistant with local processing"

from .core import AIEngine, ContextManager, RequestProcessor

__all__ = ["AIEngine", "ContextManager", "RequestProcessor"]