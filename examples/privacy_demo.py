#!/usr/bin/env python3
"""
Example: Privacy Features Demo
Demonstrates privacy controls and data management
"""
import asyncio
import json
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from localmind.privacy import PrivacyManager, PrivacySettings

async def privacy_example():
    """Demonstrate privacy features"""
    print("🔒 LocalMind V1 - Privacy Example")
    print("=" * 40)
    
    # Initialize privacy manager
    privacy_manager = PrivacyManager("./privacy_example_data")
    user_id = "privacy_user"
    
    # Create privacy settings
    settings = privacy_manager.create_privacy_settings(user_id)
    print("✓ Created privacy settings")
    
    # Customize privacy settings
    settings.data_retention_days = 30  # Keep data for 30 days
    settings.voice_data_retention = False  # Don't keep voice data
    settings.location_tracking = False  # No location tracking
    settings.learning_enabled = True  # Allow learning from interactions
    
    privacy_manager.update_privacy_settings(settings)
    print("✓ Updated privacy preferences")
    
    # Log some data access (simulated)
    privacy_manager.log_data_access(user_id, "messages", "user_request", "core")
    privacy_manager.log_data_access(user_id, "calendar", "scheduling", "automation")
    privacy_manager.log_data_access(user_id, "contacts", "name_lookup", "communication")
    print("✓ Logged data access events")
    
    # Check permissions
    can_access_contacts = privacy_manager.check_data_access_permission(user_id, "contacts")
    can_access_location = privacy_manager.check_data_access_permission(user_id, "location")
    
    print(f"📞 Contact access allowed: {can_access_contacts}")
    print(f"📍 Location access allowed: {can_access_location}")
    
    # Get access logs
    logs = privacy_manager.get_access_logs(user_id, days=1)
    print(f"\n📜 Access logs (last 24h): {len(logs)} events")
    for log in logs:
        print(f"   {log.timestamp.strftime('%H:%M')} - {log.data_type} ({log.access_reason})")
    
    # Generate privacy report
    report = privacy_manager.generate_privacy_report(user_id)
    print(f"\n📊 Privacy Report:")
    print(f"   Data retention: {report['data_retention_days']} days")
    print(f"   Total access events: {report['permissions_summary']['total_access_events_30_days']}")
    print(f"   Encryption enabled: {report['privacy_controls']['encryption_enabled']}")
    
    if report.get('recommendations'):
        print(f"   Recommendations:")
        for rec in report['recommendations']:
            print(f"     • {rec}")
    
    # Export user data (GDPR compliance)
    export_data = privacy_manager.export_user_data(user_id)
    print(f"\n💾 Data export: {len(str(export_data))} bytes")
    
    # Show what can be deleted
    print(f"\n🗑️  Data deletion options:")
    print(f"   • Individual data types")
    print(f"   • Time-based deletion (older than X days)")
    print(f"   • Complete user data deletion")
    
    print(f"\n✅ Privacy features demonstrated!")
    print(f"   🔒 Local encryption and secure storage")
    print(f"   👁️  Transparent data access logging")
    print(f"   ⚙️  Granular permission controls")
    print(f"   📤 Data export and portability")
    print(f"   🗑️  Secure data deletion")

if __name__ == "__main__":
    asyncio.run(privacy_example())