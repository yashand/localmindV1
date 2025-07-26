"""
Context Manager for LocalMind
Handles user context, preferences, and work/personal mode switching
"""
import json
import logging
from typing import Dict, List, Optional, Any, Set
from dataclasses import dataclass, asdict
from datetime import datetime, time
import sqlite3
from pathlib import Path

logger = logging.getLogger(__name__)


@dataclass
class UserProfile:
    """User profile and preferences"""
    user_id: str
    name: str
    preferences: Dict[str, Any]
    work_context: Dict[str, Any]
    personal_context: Dict[str, Any]
    learning_data: Dict[str, Any]
    created_at: datetime
    updated_at: datetime


@dataclass 
class ContextRule:
    """Rules for automatic context switching"""
    name: str
    trigger_type: str  # time, location, calendar, manual
    trigger_value: Any
    target_mode: str
    priority: int
    active: bool = True


class ContextManager:
    """
    Manages user context, profiles, and automatic mode switching
    All data stored locally with privacy-first design
    """
    
    def __init__(self, data_dir: str = "./data"):
        self.data_dir = Path(data_dir)
        self.data_dir.mkdir(exist_ok=True)
        self.db_path = self.data_dir / "context.db"
        self.current_mode = "personal"
        self.current_user_id: Optional[str] = None
        self._initialize_database()
    
    def _initialize_database(self):
        """Initialize local SQLite database for context storage"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS user_profiles (
                    user_id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    preferences TEXT,
                    work_context TEXT,
                    personal_context TEXT,
                    learning_data TEXT,
                    created_at TIMESTAMP,
                    updated_at TIMESTAMP
                )
            """)
            
            conn.execute("""
                CREATE TABLE IF NOT EXISTS context_rules (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT,
                    name TEXT,
                    trigger_type TEXT,
                    trigger_value TEXT,
                    target_mode TEXT,
                    priority INTEGER,
                    active BOOLEAN,
                    FOREIGN KEY (user_id) REFERENCES user_profiles (user_id)
                )
            """)
            
            conn.execute("""
                CREATE TABLE IF NOT EXISTS context_history (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT,
                    timestamp TIMESTAMP,
                    mode TEXT,
                    trigger_reason TEXT,
                    context_snapshot TEXT,
                    FOREIGN KEY (user_id) REFERENCES user_profiles (user_id)
                )
            """)
            
            conn.commit()
            logger.info("Context database initialized")
    
    def create_user_profile(self, user_id: str, name: str, initial_preferences: Optional[Dict] = None) -> UserProfile:
        """Create a new user profile"""
        now = datetime.now()
        profile = UserProfile(
            user_id=user_id,
            name=name,
            preferences=initial_preferences or {},
            work_context={},
            personal_context={},
            learning_data={},
            created_at=now,
            updated_at=now
        )
        
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                INSERT INTO user_profiles 
                (user_id, name, preferences, work_context, personal_context, learning_data, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                profile.user_id,
                profile.name,
                json.dumps(profile.preferences),
                json.dumps(profile.work_context),
                json.dumps(profile.personal_context),
                json.dumps(profile.learning_data),
                profile.created_at,
                profile.updated_at
            ))
            conn.commit()
        
        logger.info(f"Created user profile for {user_id}")
        return profile
    
    def get_user_profile(self, user_id: str) -> Optional[UserProfile]:
        """Get user profile by ID"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.execute("""
                SELECT user_id, name, preferences, work_context, personal_context, 
                       learning_data, created_at, updated_at
                FROM user_profiles WHERE user_id = ?
            """, (user_id,))
            
            row = cursor.fetchone()
            if not row:
                return None
            
            return UserProfile(
                user_id=row[0],
                name=row[1],
                preferences=json.loads(row[2]),
                work_context=json.loads(row[3]),
                personal_context=json.loads(row[4]),
                learning_data=json.loads(row[5]),
                created_at=datetime.fromisoformat(row[6]),
                updated_at=datetime.fromisoformat(row[7])
            )
    
    def update_user_context(self, user_id: str, context_type: str, updates: Dict[str, Any]):
        """Update user context (work or personal)"""
        profile = self.get_user_profile(user_id)
        if not profile:
            raise ValueError(f"User profile not found: {user_id}")
        
        if context_type == "work":
            profile.work_context.update(updates)
        elif context_type == "personal":
            profile.personal_context.update(updates)
        else:
            raise ValueError(f"Invalid context type: {context_type}")
        
        profile.updated_at = datetime.now()
        
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                UPDATE user_profiles 
                SET work_context = ?, personal_context = ?, updated_at = ?
                WHERE user_id = ?
            """, (
                json.dumps(profile.work_context),
                json.dumps(profile.personal_context),
                profile.updated_at,
                user_id
            ))
            conn.commit()
        
        logger.info(f"Updated {context_type} context for user {user_id}")
    
    def add_context_rule(self, user_id: str, rule: ContextRule):
        """Add automatic context switching rule"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                INSERT INTO context_rules 
                (user_id, name, trigger_type, trigger_value, target_mode, priority, active)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (
                user_id,
                rule.name,
                rule.trigger_type,
                json.dumps(rule.trigger_value),
                rule.target_mode,
                rule.priority,
                rule.active
            ))
            conn.commit()
        
        logger.info(f"Added context rule '{rule.name}' for user {user_id}")
    
    def get_context_rules(self, user_id: str) -> List[ContextRule]:
        """Get all context rules for user"""
        rules = []
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.execute("""
                SELECT name, trigger_type, trigger_value, target_mode, priority, active
                FROM context_rules WHERE user_id = ? AND active = 1
                ORDER BY priority DESC
            """, (user_id,))
            
            for row in cursor.fetchall():
                rules.append(ContextRule(
                    name=row[0],
                    trigger_type=row[1],
                    trigger_value=json.loads(row[2]),
                    target_mode=row[3],
                    priority=row[4],
                    active=bool(row[5])
                ))
        
        return rules
    
    def evaluate_context_switch(self, user_id: str, current_context: Dict[str, Any]) -> Optional[str]:
        """Evaluate if context should switch based on rules and current state"""
        rules = self.get_context_rules(user_id)
        
        for rule in rules:
            if self._rule_matches(rule, current_context):
                logger.info(f"Context switch triggered by rule '{rule.name}' to {rule.target_mode}")
                return rule.target_mode
        
        return None
    
    def _rule_matches(self, rule: ContextRule, context: Dict[str, Any]) -> bool:
        """Check if a context rule matches current conditions"""
        if rule.trigger_type == "time":
            current_time = datetime.now().time()
            start_time = time.fromisoformat(rule.trigger_value["start"])
            end_time = time.fromisoformat(rule.trigger_value["end"])
            return start_time <= current_time <= end_time
        
        elif rule.trigger_type == "location":
            current_location = context.get("location")
            return current_location == rule.trigger_value
        
        elif rule.trigger_type == "calendar":
            calendar_events = context.get("calendar_events", [])
            for event in calendar_events:
                if rule.trigger_value in event.get("title", "").lower():
                    return True
        
        return False
    
    def switch_mode(self, user_id: str, new_mode: str, reason: str = "manual"):
        """Switch to new mode and log the change"""
        old_mode = self.current_mode
        self.current_mode = new_mode
        self.current_user_id = user_id
        
        # Log context switch
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                INSERT INTO context_history 
                (user_id, timestamp, mode, trigger_reason, context_snapshot)
                VALUES (?, ?, ?, ?, ?)
            """, (
                user_id,
                datetime.now(),
                new_mode,
                reason,
                json.dumps({"previous_mode": old_mode})
            ))
            conn.commit()
        
        logger.info(f"Switched from {old_mode} to {new_mode} mode (reason: {reason})")
    
    def get_current_context(self, user_id: str) -> Dict[str, Any]:
        """Get current context for the user based on active mode"""
        profile = self.get_user_profile(user_id)
        if not profile:
            return {}
        
        if self.current_mode == "work":
            return profile.work_context
        elif self.current_mode == "personal":
            return profile.personal_context
        else:  # mixed mode
            # Combine contexts with work taking priority for conflicts
            combined = profile.personal_context.copy()
            combined.update(profile.work_context)
            return combined
    
    def learn_from_interaction(self, user_id: str, interaction_data: Dict[str, Any]):
        """Update learning data based on user interaction"""
        profile = self.get_user_profile(user_id)
        if not profile:
            return
        
        # Update learning data
        learning_key = f"{self.current_mode}_interactions"
        if learning_key not in profile.learning_data:
            profile.learning_data[learning_key] = []
        
        interaction_data["timestamp"] = datetime.now().isoformat()
        interaction_data["mode"] = self.current_mode
        profile.learning_data[learning_key].append(interaction_data)
        
        # Keep only recent interactions (last 1000)
        profile.learning_data[learning_key] = profile.learning_data[learning_key][-1000:]
        
        # Update database
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                UPDATE user_profiles 
                SET learning_data = ?, updated_at = ?
                WHERE user_id = ?
            """, (
                json.dumps(profile.learning_data),
                datetime.now(),
                user_id
            ))
            conn.commit()
        
        logger.debug(f"Updated learning data for user {user_id}")
    
    def get_privacy_report(self, user_id: str) -> Dict[str, Any]:
        """Generate privacy report showing what data is stored"""
        profile = self.get_user_profile(user_id)
        if not profile:
            return {}
        
        with sqlite3.connect(self.db_path) as conn:
            # Count interactions
            cursor = conn.execute("""
                SELECT COUNT(*) FROM context_history WHERE user_id = ?
            """, (user_id,))
            interaction_count = cursor.fetchone()[0]
            
            # Count rules
            cursor = conn.execute("""
                SELECT COUNT(*) FROM context_rules WHERE user_id = ?
            """, (user_id,))
            rules_count = cursor.fetchone()[0]
        
        return {
            "user_id": user_id,
            "profile_created": profile.created_at.isoformat(),
            "last_updated": profile.updated_at.isoformat(),
            "total_interactions": interaction_count,
            "context_rules": rules_count,
            "work_context_keys": list(profile.work_context.keys()),
            "personal_context_keys": list(profile.personal_context.keys()),
            "learning_data_size": len(str(profile.learning_data)),
            "storage_location": str(self.db_path)
        }