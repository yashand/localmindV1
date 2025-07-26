"""
Request Processor for LocalMind
Orchestrates request handling between AI engine, context manager, and other modules
"""
import asyncio
import logging
from typing import Dict, List, Optional, Any
from datetime import datetime

from .engine import AIEngine, AIRequest, AIResponse, ProcessingMode
from .context import ContextManager

logger = logging.getLogger(__name__)


class RequestProcessor:
    """
    Central request processor that orchestrates AI assistant functionality
    Handles request routing, context management, and response generation
    """
    
    def __init__(self, ai_engine: AIEngine, context_manager: ContextManager):
        self.ai_engine = ai_engine
        self.context_manager = context_manager
        self.request_history: List[Dict[str, Any]] = []
        
    async def process_user_request(
        self, 
        user_id: str, 
        text: str, 
        voice_input: bool = False,
        additional_context: Optional[Dict[str, Any]] = None
    ) -> AIResponse:
        """
        Process a user request end-to-end
        
        Args:
            user_id: Unique user identifier
            text: Request text (from voice or chat)
            voice_input: Whether input came from voice
            additional_context: Additional context data
            
        Returns:
            AIResponse with generated response and actions
        """
        try:
            # Get or create user profile
            profile = self.context_manager.get_user_profile(user_id)
            if not profile:
                # Create default profile for new user
                profile = self.context_manager.create_user_profile(
                    user_id=user_id,
                    name=f"User_{user_id[:8]}",
                    initial_preferences={}
                )
            
            # Evaluate context switching
            current_context = additional_context or {}
            new_mode = self.context_manager.evaluate_context_switch(user_id, current_context)
            if new_mode:
                self.context_manager.switch_mode(user_id, new_mode, "automatic")
            
            # Get current context and mode
            user_context = self.context_manager.get_current_context(user_id)
            current_mode = ProcessingMode(self.context_manager.current_mode)
            
            # Build AI request
            ai_request = AIRequest(
                text=text,
                mode=current_mode,
                context=user_context,
                user_id=user_id,
                timestamp=datetime.now().timestamp(),
                voice_input=voice_input
            )
            
            # Process with AI engine
            response = await self.ai_engine.process_request(ai_request)
            
            # Log interaction for learning
            interaction_data = {
                "request_text": text,
                "response_text": response.text,
                "actions_count": len(response.actions),
                "confidence": response.confidence,
                "voice_input": voice_input
            }
            self.context_manager.learn_from_interaction(user_id, interaction_data)
            
            # Store in request history
            self.request_history.append({
                "timestamp": ai_request.timestamp,
                "user_id": user_id,
                "request": text,
                "response": response.text,
                "mode": current_mode.value,
                "actions": response.actions
            })
            
            # Keep only recent history (last 100 requests)
            self.request_history = self.request_history[-100:]
            
            logger.info(f"Processed request for user {user_id}: {text[:50]}...")
            return response
            
        except Exception as e:
            logger.error(f"Error processing request: {e}")
            # Return error response
            return AIResponse(
                text="I'm sorry, I encountered an error processing your request. Please try again.",
                actions=[],
                context_updates={},
                confidence=0.0,
                requires_confirmation=False
            )
    
    async def handle_mode_switch(self, user_id: str, target_mode: str) -> str:
        """Handle explicit mode switching request"""
        try:
            valid_modes = ["work", "personal", "mixed"]
            if target_mode not in valid_modes:
                return f"Invalid mode '{target_mode}'. Valid modes are: {', '.join(valid_modes)}"
            
            self.context_manager.switch_mode(user_id, target_mode, "manual")
            return f"Switched to {target_mode} mode"
            
        except Exception as e:
            logger.error(f"Error switching mode: {e}")
            return "Error switching mode. Please try again."
    
    async def get_context_summary(self, user_id: str) -> Dict[str, Any]:
        """Get summary of current context and recent activity"""
        try:
            profile = self.context_manager.get_user_profile(user_id)
            if not profile:
                return {"error": "User profile not found"}
            
            # Get recent requests for this user
            recent_requests = [
                req for req in self.request_history[-20:] 
                if req["user_id"] == user_id
            ]
            
            return {
                "user_name": profile.name,
                "current_mode": self.context_manager.current_mode,
                "last_updated": profile.updated_at.isoformat(),
                "recent_requests_count": len(recent_requests),
                "work_context_active": bool(profile.work_context),
                "personal_context_active": bool(profile.personal_context),
                "learning_interactions": len(profile.learning_data.get("personal_interactions", []) + 
                                             profile.learning_data.get("work_interactions", []))
            }
            
        except Exception as e:
            logger.error(f"Error getting context summary: {e}")
            return {"error": "Failed to get context summary"}
    
    async def update_user_preferences(self, user_id: str, preferences: Dict[str, Any]) -> bool:
        """Update user preferences"""
        try:
            profile = self.context_manager.get_user_profile(user_id)
            if not profile:
                return False
            
            profile.preferences.update(preferences)
            profile.updated_at = datetime.now()
            
            # Save to database (this would need to be implemented in context manager)
            # For now, just log the update
            logger.info(f"Updated preferences for user {user_id}: {preferences}")
            return True
            
        except Exception as e:
            logger.error(f"Error updating preferences: {e}")
            return False
    
    async def add_automation_rule(self, user_id: str, rule_data: Dict[str, Any]) -> bool:
        """Add new automation rule for the user"""
        try:
            from ..automation.rules import AutomationRule
            
            # Create automation rule
            rule = AutomationRule(
                name=rule_data["name"],
                trigger=rule_data["trigger"],
                actions=rule_data["actions"],
                conditions=rule_data.get("conditions", {}),
                user_id=user_id
            )
            
            # This would integrate with automation module
            logger.info(f"Added automation rule '{rule.name}' for user {user_id}")
            return True
            
        except Exception as e:
            logger.error(f"Error adding automation rule: {e}")
            return False
    
    async def get_daily_summary(self, user_id: str) -> Dict[str, Any]:
        """Generate daily activity summary for user"""
        try:
            # Get today's requests
            today = datetime.now().date()
            today_requests = [
                req for req in self.request_history 
                if (req["user_id"] == user_id and 
                    datetime.fromtimestamp(req["timestamp"]).date() == today)
            ]
            
            # Analyze request patterns
            mode_counts = {}
            action_types = {}
            
            for req in today_requests:
                mode = req["mode"]
                mode_counts[mode] = mode_counts.get(mode, 0) + 1
                
                for action in req["actions"]:
                    action_type = action.get("type", "unknown")
                    action_types[action_type] = action_types.get(action_type, 0) + 1
            
            return {
                "date": today.isoformat(),
                "total_requests": len(today_requests),
                "mode_distribution": mode_counts,
                "action_types": action_types,
                "most_active_mode": max(mode_counts.items(), key=lambda x: x[1])[0] if mode_counts else None,
                "suggestions": self._generate_daily_suggestions(today_requests)
            }
            
        except Exception as e:
            logger.error(f"Error generating daily summary: {e}")
            return {"error": "Failed to generate daily summary"}
    
    def _generate_daily_suggestions(self, requests: List[Dict[str, Any]]) -> List[str]:
        """Generate suggestions based on daily activity patterns"""
        suggestions = []
        
        if len(requests) > 10:
            suggestions.append("You've been quite active today! Consider setting up automation rules for common tasks.")
        
        work_requests = [r for r in requests if r["mode"] == "work"]
        if len(work_requests) > 5:
            suggestions.append("Consider creating work-specific shortcuts for your frequent tasks.")
        
        return suggestions
    
    def get_request_history(self, user_id: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Get recent request history for user"""
        user_requests = [
            req for req in self.request_history[-limit*2:] 
            if req["user_id"] == user_id
        ]
        return user_requests[-limit:]
    
    def clear_user_data(self, user_id: str) -> bool:
        """Clear all data for a user (privacy compliance)"""
        try:
            # Remove from request history
            self.request_history = [
                req for req in self.request_history 
                if req["user_id"] != user_id
            ]
            
            # This would also clear from context manager and other modules
            logger.info(f"Cleared data for user {user_id}")
            return True
            
        except Exception as e:
            logger.error(f"Error clearing user data: {e}")
            return False