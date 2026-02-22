"""
Notification helper functions
Creates notifications for admin dashboard
Avoids circular imports by being independent of routes
"""

from database import get_collection, Collections
from datetime import datetime


def send_push_notification(title: str, message: str, target_role: str = 'all'):
    """
    Send push notification via FCM
    """
    try:
        from firebase import firebase_module
        # Try to import FCM from firebase module
        # This will fail gracefully if Firebase is not configured
        pass
    except ImportError:
        pass
    except Exception as e:
        print(f'Push notification error: {e}')


def create_notification(
    title: str, 
    message: str, 
    notification_type: str = 'info',
    target_role: str = 'all',  # 'all', 'student', 'faculty', 'admin'
    target_courses: list = None,  # List of courses for students (e.g., ['BCA', 'BBA'])
    target_semesters: list = None,  # List of semesters for students (e.g., ['1st', '2nd'])
    sender_role: str = 'admin',  # 'admin', 'faculty'
    sender_id: str = None,
    sender_name: str = None,
    related_id: str = None,  # ID of related entity (notice, assignment, etc.)
    related_type: str = None,  # 'notice', 'assignment', 'material', 'event'
    send_push: bool = True  # Whether to send push notification
):
    """
    Create a new notification in the database with role-based targeting
    
    Parameters:
    - title: Notification title
    - message: Notification message
    - notification_type: Type of notification ('notice', 'event', 'assignment', 'upload', 'user_register', 'user_login', 'system')
    - target_role: Target role ('all', 'student', 'faculty', 'admin')
    - target_courses: List of courses for students (e.g., ['BCA', 'BBA'])
    - target_semesters: List of semesters for students (e.g., ['1st', '2nd'])
    - sender_role: Role of sender ('admin', 'faculty')
    - sender_id: ID of sender
    - sender_name: Name of sender
    - related_id: ID of related entity
    - related_type: Type of related entity ('notice', 'assignment', 'material', 'event')
    """
    try:
        notifications = get_collection(Collections.NOTIFICATIONS)
        
        notification_doc = {
            'title': title,
            'message': message,
            'type': notification_type,
            'target_role': target_role,
            'target_courses': target_courses or [],
            'target_semesters': target_semesters or [],
            'sender_role': sender_role,
            'sender_id': sender_id,
            'sender_name': sender_name,
            'related_id': related_id,
            'related_type': related_type,
            'is_read': False,
            'created_at': datetime.utcnow()
        }
        
        result = notifications.insert_one(notification_doc)
        notification_id = str(result.inserted_id)
        
        # Send push notification if enabled
        if send_push:
            try:
                # Import from firebase module in same directory
                import firebase as firebase_module
                if hasattr(firebase_module, 'send_push_notification'):
                    data_payload = {
                        'notification_id': notification_id,
                        'type': notification_type,
                        'related_type': related_type or '',
                        'related_id': related_id or '',
                    }
                    firebase_module.send_push_notification(title, message, target_role, data_payload)
            except (ImportError, Exception) as e:
                # Firebase not configured or error, skip push silently
                pass
        
        return notification_id
    except Exception as e:
        print(f"Error creating notification: {e}")
        return None


def get_notifications_for_user(
    user_role: str,
    user_id: str,
    user_courses: list = None,
    user_semesters: list = None
):
    """
    Get notifications filtered by user role, courses, and semesters
    
    Parameters:
    - user_role: Role of the user ('student', 'faculty', 'admin')
    - user_id: ID of the user
    - user_courses: List of courses the student is enrolled in
    - user_semesters: List of semesters the student is in
    
    Returns:
    - List of notifications visible to this user
    """
    try:
        notifications = get_collection(Collections.NOTIFICATIONS)
        
        # Build query based on targeting rules
        queries = []
        
        # Rule 1: Notifications for 'all' are visible to everyone
        queries.append({'target_role': 'all'})
        
        # Rule 2: Role-specific notifications
        if user_role == 'admin':
            # Admin sees notifications targeted to admin or all
            queries.append({'target_role': 'admin'})
        elif user_role == 'faculty':
            # Faculty sees notifications targeted to faculty or all
            queries.append({'target_role': 'faculty'})
        elif user_role == 'student':
            # Students see notifications targeted to them
            # Need to check if notification is for 'student' OR for specific courses/semesters
            
            student_query = {
                'target_role': 'student',
                '$or': [
                    {'target_courses': {'$size': 0}},  # No course restriction = all students
                    {'target_courses': {'$in': user_courses or []}},  # Matches user's courses
                ]
            }
            queries.append(student_query)
            
            # Also check semester-specific notifications
            if user_semesters:
                semester_query = {
                    'target_role': 'student',
                    'target_semesters': {'$in': user_semesters}
                }
                queries.append(semester_query)
        
        # Combine queries with OR
        if queries:
            final_query = {'$or': queries}
        else:
            final_query = {}
        
        # Get notifications sorted by date (newest first)
        notification_list = list(notifications.find(final_query).sort('created_at', -1))
        
        # Convert ObjectId to string
        for notif in notification_list:
            notif['_id'] = str(notif['_id'])
        
        return notification_list
    except Exception as e:
        print(f"Error getting notifications for user: {e}")
        return []
