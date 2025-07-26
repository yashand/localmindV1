"""
Privacy and Security Module for LocalMind
Handles encryption, data protection, and privacy controls
"""
import hashlib
import secrets
import logging
from typing import Dict, List, Optional, Any, Tuple
from datetime import datetime, timedelta
from pathlib import Path
import json
import sqlite3
from dataclasses import dataclass

from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
import base64

logger = logging.getLogger(__name__)


@dataclass
class PrivacySettings:
    """User privacy settings"""
    user_id: str
    data_retention_days: int
    learning_enabled: bool
    cross_device_sync: bool
    voice_data_retention: bool
    location_tracking: bool
    contact_access: bool
    calendar_access: bool
    message_access: bool
    auto_delete_enabled: bool
    encryption_enabled: bool


@dataclass
class DataAccessLog:
    """Log entry for data access"""
    timestamp: datetime
    user_id: str
    data_type: str
    access_reason: str
    module: str


class EncryptionManager:
    """Manages local data encryption"""
    
    def __init__(self, key_file: str = "encryption.key"):
        self.key_file = Path(key_file)
        self._key = None
        self._load_or_create_key()
    
    def _load_or_create_key(self):
        """Load existing key or create new one"""
        if self.key_file.exists():
            with open(self.key_file, 'rb') as f:
                self._key = f.read()
        else:
            self._key = Fernet.generate_key()
            with open(self.key_file, 'wb') as f:
                f.write(self._key)
            # Set restrictive permissions
            self.key_file.chmod(0o600)
        
        logger.info("Encryption key loaded")
    
    def encrypt_data(self, data: str) -> str:
        """Encrypt string data"""
        f = Fernet(self._key)
        encrypted = f.encrypt(data.encode())
        return base64.b64encode(encrypted).decode()
    
    def decrypt_data(self, encrypted_data: str) -> str:
        """Decrypt string data"""
        f = Fernet(self._key)
        encrypted_bytes = base64.b64decode(encrypted_data.encode())
        decrypted = f.decrypt(encrypted_bytes)
        return decrypted.decode()
    
    def encrypt_file(self, file_path: Path) -> None:
        """Encrypt file in place"""
        with open(file_path, 'rb') as f:
            data = f.read()
        
        f = Fernet(self._key)
        encrypted = f.encrypt(data)
        
        with open(file_path, 'wb') as f:
            f.write(encrypted)
    
    def decrypt_file(self, file_path: Path) -> bytes:
        """Decrypt file and return content"""
        with open(file_path, 'rb') as f:
            encrypted_data = f.read()
        
        f = Fernet(self._key)
        return f.decrypt(encrypted_data)


class PrivacyManager:
    """
    Manages privacy settings, data access controls, and compliance
    """
    
    def __init__(self, data_dir: str = "./data"):
        self.data_dir = Path(data_dir)
        self.data_dir.mkdir(exist_ok=True)
        self.db_path = self.data_dir / "privacy.db"
        self.encryption = EncryptionManager(self.data_dir / "encryption.key")
        self.access_logs: List[DataAccessLog] = []
        self._initialize_database()
    
    def _initialize_database(self):
        """Initialize privacy database"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS privacy_settings (
                    user_id TEXT PRIMARY KEY,
                    data_retention_days INTEGER,
                    learning_enabled BOOLEAN,
                    cross_device_sync BOOLEAN,
                    voice_data_retention BOOLEAN,
                    location_tracking BOOLEAN,
                    contact_access BOOLEAN,
                    calendar_access BOOLEAN,
                    message_access BOOLEAN,
                    auto_delete_enabled BOOLEAN,
                    encryption_enabled BOOLEAN,
                    created_at TIMESTAMP,
                    updated_at TIMESTAMP
                )
            """)
            
            conn.execute("""
                CREATE TABLE IF NOT EXISTS data_access_logs (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp TIMESTAMP,
                    user_id TEXT,
                    data_type TEXT,
                    access_reason TEXT,
                    module TEXT
                )
            """)
            
            conn.execute("""
                CREATE TABLE IF NOT EXISTS data_deletion_logs (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp TIMESTAMP,
                    user_id TEXT,
                    data_type TEXT,
                    deletion_reason TEXT,
                    items_deleted INTEGER
                )
            """)
            
            conn.commit()
            logger.info("Privacy database initialized")
    
    def create_privacy_settings(self, user_id: str) -> PrivacySettings:
        """Create default privacy settings for new user"""
        settings = PrivacySettings(
            user_id=user_id,
            data_retention_days=90,  # Default 90 days
            learning_enabled=True,
            cross_device_sync=True,
            voice_data_retention=False,  # Default to not keeping voice data
            location_tracking=False,  # Default to no location tracking
            contact_access=False,
            calendar_access=False,
            message_access=False,
            auto_delete_enabled=True,
            encryption_enabled=True
        )
        
        self._save_privacy_settings(settings)
        return settings
    
    def get_privacy_settings(self, user_id: str) -> Optional[PrivacySettings]:
        """Get privacy settings for user"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.execute("""
                SELECT user_id, data_retention_days, learning_enabled, cross_device_sync,
                       voice_data_retention, location_tracking, contact_access, calendar_access,
                       message_access, auto_delete_enabled, encryption_enabled
                FROM privacy_settings WHERE user_id = ?
            """, (user_id,))
            
            row = cursor.fetchone()
            if not row:
                return None
            
            return PrivacySettings(*row)
    
    def update_privacy_settings(self, settings: PrivacySettings) -> bool:
        """Update privacy settings"""
        try:
            self._save_privacy_settings(settings)
            logger.info(f"Updated privacy settings for user {settings.user_id}")
            return True
        except Exception as e:
            logger.error(f"Failed to update privacy settings: {e}")
            return False
    
    def _save_privacy_settings(self, settings: PrivacySettings):
        """Save privacy settings to database"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                INSERT OR REPLACE INTO privacy_settings 
                (user_id, data_retention_days, learning_enabled, cross_device_sync,
                 voice_data_retention, location_tracking, contact_access, calendar_access,
                 message_access, auto_delete_enabled, encryption_enabled, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                settings.user_id,
                settings.data_retention_days,
                settings.learning_enabled,
                settings.cross_device_sync,
                settings.voice_data_retention,
                settings.location_tracking,
                settings.contact_access,
                settings.calendar_access,
                settings.message_access,
                settings.auto_delete_enabled,
                settings.encryption_enabled,
                datetime.now(),
                datetime.now()
            ))
            conn.commit()
    
    def log_data_access(self, user_id: str, data_type: str, access_reason: str, module: str):
        """Log data access for transparency"""
        log_entry = DataAccessLog(
            timestamp=datetime.now(),
            user_id=user_id,
            data_type=data_type,
            access_reason=access_reason,
            module=module
        )
        
        self.access_logs.append(log_entry)
        
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                INSERT INTO data_access_logs (timestamp, user_id, data_type, access_reason, module)
                VALUES (?, ?, ?, ?, ?)
            """, (log_entry.timestamp, log_entry.user_id, log_entry.data_type, 
                 log_entry.access_reason, log_entry.module))
            conn.commit()
    
    def get_access_logs(self, user_id: str, days: int = 7) -> List[DataAccessLog]:
        """Get recent access logs for user"""
        since_date = datetime.now() - timedelta(days=days)
        
        logs = []
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.execute("""
                SELECT timestamp, user_id, data_type, access_reason, module
                FROM data_access_logs 
                WHERE user_id = ? AND timestamp > ?
                ORDER BY timestamp DESC
            """, (user_id, since_date))
            
            for row in cursor.fetchall():
                logs.append(DataAccessLog(
                    timestamp=datetime.fromisoformat(row[0]),
                    user_id=row[1],
                    data_type=row[2],
                    access_reason=row[3],
                    module=row[4]
                ))
        
        return logs
    
    def check_data_access_permission(self, user_id: str, data_type: str) -> bool:
        """Check if access to specific data type is allowed"""
        settings = self.get_privacy_settings(user_id)
        if not settings:
            return False
        
        permission_map = {
            "contacts": settings.contact_access,
            "calendar": settings.calendar_access,
            "messages": settings.message_access,
            "location": settings.location_tracking,
            "voice": settings.voice_data_retention
        }
        
        return permission_map.get(data_type, False)
    
    def auto_delete_old_data(self, user_id: str) -> Dict[str, int]:
        """Auto-delete old data based on retention settings"""
        settings = self.get_privacy_settings(user_id)
        if not settings or not settings.auto_delete_enabled:
            return {}
        
        cutoff_date = datetime.now() - timedelta(days=settings.data_retention_days)
        deleted_counts = {}
        
        # This would integrate with other modules to delete old data
        # For now, just log the deletion
        
        with sqlite3.connect(self.db_path) as conn:
            # Delete old access logs
            cursor = conn.execute("""
                DELETE FROM data_access_logs 
                WHERE user_id = ? AND timestamp < ?
            """, (user_id, cutoff_date))
            deleted_counts["access_logs"] = cursor.rowcount
            
            # Log the deletion
            conn.execute("""
                INSERT INTO data_deletion_logs (timestamp, user_id, data_type, deletion_reason, items_deleted)
                VALUES (?, ?, ?, ?, ?)
            """, (datetime.now(), user_id, "access_logs", "auto_retention", deleted_counts["access_logs"]))
            
            conn.commit()
        
        logger.info(f"Auto-deleted old data for user {user_id}: {deleted_counts}")
        return deleted_counts
    
    def export_user_data(self, user_id: str) -> Dict[str, Any]:
        """Export all user data for portability/compliance"""
        settings = self.get_privacy_settings(user_id)
        access_logs = self.get_access_logs(user_id, days=365)  # Full year
        
        export_data = {
            "user_id": user_id,
            "export_timestamp": datetime.now().isoformat(),
            "privacy_settings": {
                "data_retention_days": settings.data_retention_days if settings else None,
                "learning_enabled": settings.learning_enabled if settings else None,
                "permissions": {
                    "cross_device_sync": settings.cross_device_sync if settings else None,
                    "voice_data_retention": settings.voice_data_retention if settings else None,
                    "location_tracking": settings.location_tracking if settings else None,
                    "contact_access": settings.contact_access if settings else None,
                    "calendar_access": settings.calendar_access if settings else None,
                    "message_access": settings.message_access if settings else None,
                }
            },
            "access_logs": [
                {
                    "timestamp": log.timestamp.isoformat(),
                    "data_type": log.data_type,
                    "access_reason": log.access_reason,
                    "module": log.module
                }
                for log in access_logs
            ]
        }
        
        return export_data
    
    def delete_all_user_data(self, user_id: str) -> bool:
        """Permanently delete all user data"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                # Delete privacy settings
                conn.execute("DELETE FROM privacy_settings WHERE user_id = ?", (user_id,))
                
                # Delete access logs
                conn.execute("DELETE FROM data_access_logs WHERE user_id = ?", (user_id,))
                
                # Log the deletion
                conn.execute("""
                    INSERT INTO data_deletion_logs 
                    (timestamp, user_id, data_type, deletion_reason, items_deleted)
                    VALUES (?, ?, ?, ?, ?)
                """, (datetime.now(), user_id, "all_data", "user_request", 1))
                
                conn.commit()
            
            logger.info(f"Deleted all data for user {user_id}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to delete user data: {e}")
            return False
    
    def generate_privacy_report(self, user_id: str) -> Dict[str, Any]:
        """Generate comprehensive privacy report"""
        settings = self.get_privacy_settings(user_id)
        recent_access = self.get_access_logs(user_id, days=30)
        
        # Analyze access patterns
        access_by_type = {}
        access_by_module = {}
        
        for log in recent_access:
            access_by_type[log.data_type] = access_by_type.get(log.data_type, 0) + 1
            access_by_module[log.module] = access_by_module.get(log.module, 0) + 1
        
        return {
            "user_id": user_id,
            "report_generated": datetime.now().isoformat(),
            "data_retention_days": settings.data_retention_days if settings else "Not set",
            "permissions_summary": {
                "learning_enabled": settings.learning_enabled if settings else False,
                "cross_device_sync": settings.cross_device_sync if settings else False,
                "data_types_accessed": list(access_by_type.keys()),
                "total_access_events_30_days": len(recent_access)
            },
            "access_breakdown": {
                "by_data_type": access_by_type,
                "by_module": access_by_module
            },
            "privacy_controls": {
                "auto_delete_enabled": settings.auto_delete_enabled if settings else False,
                "encryption_enabled": settings.encryption_enabled if settings else False,
                "voice_data_retained": settings.voice_data_retention if settings else False
            },
            "recommendations": self._generate_privacy_recommendations(settings, recent_access)
        }
    
    def _generate_privacy_recommendations(self, settings: Optional[PrivacySettings], 
                                        access_logs: List[DataAccessLog]) -> List[str]:
        """Generate privacy recommendations"""
        recommendations = []
        
        if not settings:
            recommendations.append("Set up your privacy preferences to control data access")
            return recommendations
        
        if settings.data_retention_days > 365:
            recommendations.append("Consider reducing data retention period for better privacy")
        
        if not settings.encryption_enabled:
            recommendations.append("Enable encryption for enhanced data protection")
        
        if settings.voice_data_retention and len([l for l in access_logs if l.data_type == "voice"]) == 0:
            recommendations.append("Voice data retention is enabled but not being used - consider disabling")
        
        if len(access_logs) > 100:
            recommendations.append("High data access frequency detected - review which modules need access")
        
        return recommendations