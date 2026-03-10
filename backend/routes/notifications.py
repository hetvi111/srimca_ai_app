"""
Notifications routes for SRIMCA AI Backend
Handles getting and creating notifications for admin dashboard
"""

from flask import Blueprint, request, jsonify
from bson import ObjectId
from datetime import datetime

from database import get_collection, Collections
from notification_helper import create_notification, get_notifications_for_user
from auth import verify_jwt_token

# Create notifications blueprint
notifications_bp = Blueprint('notifications', __name__, url_prefix='/api')


def require_auth(f):
    """Decorator to require authentication"""
    from functools import wraps
    @wraps(f)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get('Authorization')
        if not auth_header:
            return jsonify({'error': 'No authorization header'}), 401
        
        parts = auth_header.split()
        if len(parts) != 2 or parts[0].lower() != 'bearer':
            return jsonify({'error': 'Invalid authorization header'}), 401
        
        payload = verify_jwt_token(parts[1])
        if payload is None:
            return jsonify({'error': 'Invalid or expired token'}), 401
        
        request.user = payload
        return f(*args, **kwargs)
    return decorated


@notifications_bp.route('/notifications', methods=['GET'])
def get_notifications():
    """
    Get all notifications (for admin dashboard)
    """
    try:
        notifications = get_collection(Collections.NOTIFICATIONS)
        
        # Get limit parameter (default 50)
        limit = int(request.args.get('limit', 50))
        
        # Get notifications sorted by date (newest first)
        notification_list = list(notifications.find()
                                  .sort('created_at', -1)
                                  .limit(limit))
        
        # Convert ObjectId to string
        for notif in notification_list:
            notif['_id'] = str(notif['_id'])
            if 'created_at' in notif:
                notif['created_at'] = notif['created_at'].isoformat()
        
        return jsonify({
            'notifications': notification_list,
            'count': len(notification_list)
        }), 200
    
    except Exception as e:
        print(f"Get notifications error: {e}")
        return jsonify({'error': 'Failed to get notifications'}), 500


@notifications_bp.route('/notifications/my', methods=['GET'])
@require_auth
def get_my_notifications():
    """
    Get notifications for the current user based on their role
    Requires authentication
    """
    try:
        # Get user info from token
        user_id = request.user.get('user_id')
        user_role = request.user.get('role', 'student')
        
        # Get user's courses and semesters (for students)
        users_collection = get_collection(Collections.USERS)
        user_doc = users_collection.find_one({'_id': ObjectId(user_id)})
        
        user_courses = []
        user_semesters = []
        
        if user_doc and user_role == 'student':
            profile = user_doc.get('profile', {})
            course = profile.get('course', '')
            semester = profile.get('semester', '')
            if course:
                user_courses = [course]
            if semester:
                user_semesters = [semester]
        
        # Get notifications for this user
        notifications = get_notifications_for_user(
            user_role=user_role,
            user_id=user_id,
            user_courses=user_courses,
            user_semesters=user_semesters
        )
        
        return jsonify({
            'notifications': notifications,
            'count': len(notifications)
        }), 200
    
    except Exception as e:
        print(f"Get my notifications error: {e}")
        return jsonify({'error': 'Failed to get notifications'}), 500


@notifications_bp.route('/notifications/unread-count', methods=['GET'])
def get_unread_count():
    """
    Get count of unread notifications
    """
    try:
        notifications = get_collection(Collections.NOTIFICATIONS)
        count = notifications.count_documents({'is_read': False})
        
        return jsonify({'unread_count': count}), 200
    
    except Exception as e:
        print(f"Get unread count error: {e}")
        return jsonify({'error': 'Failed to get unread count'}), 500


@notifications_bp.route('/notifications/unread-count/my', methods=['GET'])
@require_auth
def get_my_unread_count():
    """
    Get count of unread notifications for current user
    Requires authentication
    """
    try:
        user_id = request.user.get('user_id')
        user_role = request.user.get('role', 'student')
        
        # Get user's courses and semesters
        users_collection = get_collection(Collections.USERS)
        user_doc = users_collection.find_one({'_id': ObjectId(user_id)})
        
        user_courses = []
        user_semesters = []
        
        if user_doc and user_role == 'student':
            profile = user_doc.get('profile', {})
            course = profile.get('course', '')
            semester = profile.get('semester', '')
            if course:
                user_courses = [course]
            if semester:
                user_semesters = [semester]
        
        notifications = get_notifications_for_user(
            user_role=user_role,
            user_id=user_id,
            user_courses=user_courses,
            user_semesters=user_semesters
        )
        
        # Count unread
        unread_count = sum(1 for n in notifications if not n.get('is_read', False))
        
        return jsonify({'unread_count': unread_count}), 200
    
    except Exception as e:
        print(f"Get unread count error: {e}")
        return jsonify({'error': 'Failed to get unread count'}), 500


@notifications_bp.route('/notifications', methods=['POST'])
@require_auth
def create_notification_with_target():
    """
    Create a notification with specific target audience
    Requires authentication
    """
    try:
        data = request.get_json()
        
        # Get sender info from token
        sender_id = request.user.get('user_id')
        sender_role = request.user.get('role', 'admin')
        
        # Get sender name
        users_collection = get_collection(Collections.USERS)
        user_doc = users_collection.find_one({'_id': ObjectId(sender_id)})
        sender_name = user_doc.get('name', 'Unknown') if user_doc else 'Unknown'
        
        # Get notification parameters
        title = data.get('title', '')
        message = data.get('message', '')
        notification_type = data.get('type', 'notice')  # notice, event, assignment, upload, system
        target_role = data.get('target_role', 'all')  # all, student, faculty, admin
        target_courses = data.get('target_courses', [])  # List of courses for students
        target_semesters = data.get('target_semesters', [])  # List of semesters for students
        related_id = data.get('related_id')
        related_type = data.get('related_type')
        
        # Create notification
        notification_id = create_notification(
            title=title,
            message=message,
            notification_type=notification_type,
            target_role=target_role,
            target_courses=target_courses,
            target_semesters=target_semesters,
            sender_role=sender_role,
            sender_id=sender_id,
            sender_name=sender_name,
            related_id=related_id,
            related_type=related_type
        )
        
        if notification_id:
            return jsonify({
                'message': 'Notification created successfully',
                'notification_id': notification_id
            }), 201
        else:
            return jsonify({'error': 'Failed to create notification'}), 500
    
    except Exception as e:
        print(f"Create notification error: {e}")
        return jsonify({'error': 'Failed to create notification'}), 500


@notifications_bp.route('/notifications/<notification_id>/read', methods=['POST'])
def mark_as_read(notification_id):
    """
    Mark a notification as read
    """
    try:
        notifications = get_collection(Collections.NOTIFICATIONS)
        
        result = notifications.update_one(
            {'_id': ObjectId(notification_id)},
            {'$set': {'is_read': True}}
        )
        
        if result.modified_count > 0:
            return jsonify({'message': 'Notification marked as read'}), 200
        else:
            return jsonify({'error': 'Notification not found'}), 404
    
    except Exception as e:
        print(f"Mark as read error: {e}")
        return jsonify({'error': 'Failed to mark as read'}), 500


@notifications_bp.route('/notifications/read-all', methods=['POST'])
def mark_all_as_read():
    """
    Mark all notifications as read
    """
    try:
        notifications = get_collection(Collections.NOTIFICATIONS)
        
        result = notifications.update_many(
            {'is_read': False},
            {'$set': {'is_read': True}}
        )
        
        return jsonify({
            'message': 'All notifications marked as read',
            'modified_count': result.modified_count
        }), 200
    
    except Exception as e:
        print(f"Mark all as read error: {e}")
        return jsonify({'error': 'Failed to mark all as read'}), 500


@notifications_bp.route('/notifications/<notification_id>', methods=['DELETE'])
def delete_notification(notification_id):
    """
    Delete a notification
    """
    try:
        notifications = get_collection(Collections.NOTIFICATIONS)
        
        result = notifications.delete_one({'_id': ObjectId(notification_id)})
        
        if result.deleted_count > 0:
            return jsonify({'message': 'Notification deleted'}), 200
        else:
            return jsonify({'error': 'Notification not found'}), 404
    
    except Exception as e:
        print(f"Delete notification error: {e}")
        return jsonify({'error': 'Failed to delete notification'}), 500
