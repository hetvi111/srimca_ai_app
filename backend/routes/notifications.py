"""
Notifications routes for SRIMCA AI Backend
Handles getting and creating notifications for admin dashboard
"""

from flask import Blueprint, request, jsonify
from bson import ObjectId
from datetime import datetime

from database import get_collection, Collections
from notification_helper import create_notification

# Create notifications blueprint
notifications_bp = Blueprint('notifications', __name__, url_prefix='/api')


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
