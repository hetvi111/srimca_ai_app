"""
Notification helper functions
Creates notifications for admin dashboard
Avoids circular imports by being independent of routes
"""

from database import get_collection, Collections


def create_notification(title: str, message: str, notification_type: str = 'info'):
    """
    Create a new notification in the database
    """
    try:
        from datetime import datetime
        
        notifications = get_collection(Collections.NOTIFICATIONS)
        
        notification_doc = {
            'title': title,
            'message': message,
            'type': notification_type,  # 'user_register', 'user_login', 'upload', 'system'
            'is_read': False,
            'created_at': datetime.utcnow()
        }
        
        result = notifications.insert_one(notification_doc)
        return str(result.inserted_id)
    except Exception as e:
        print(f"Error creating notification: {e}")
        return None
