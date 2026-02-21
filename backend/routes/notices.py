"""
Notice management routes for SRIMCA AI Backend
Handles CRUD operations for college notices
"""

from flask import Blueprint, request, jsonify
from bson import ObjectId
from datetime import datetime

from database import get_collection, Collections
from models import NoticeModel
from auth import verify_jwt_token
from notification_helper import create_notification

# Create notices blueprint
notices_bp = Blueprint('notices', __name__, url_prefix='/api/notices')


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


@notices_bp.route('/', methods=['GET'])
def get_notices():
    """
    Get all notices
    Query params: limit, offset, priority, faculty_id
    """
    try:
        # Parse query parameters
        limit = int(request.args.get('limit', 100))
        offset = int(request.args.get('offset', 0))
        priority = request.args.get('priority')
        faculty_id = request.args.get('faculty_id')
        
        # Build query
        query = {'is_active': True}
        
        if priority:
            query['priority'] = priority
        
        if faculty_id:
            query['faculty_id'] = faculty_id
        
        # Get notices from database
        notices_collection = get_collection(Collections.NOTICES)
        notices = list(notices_collection.find(query)
                      .sort('created_at', -1)
                      .skip(offset)
                      .limit(limit))
        
        # Convert to dict
        result = [NoticeModel.to_dict(n) for n in notices]
        
        return jsonify({
            'notices': result,
            'count': len(result),
            'total': notices_collection.count_documents(query)
        }), 200
    
    except Exception as e:
        print(f"Get notices error: {e}")
        return jsonify({'error': 'Failed to get notices'}), 500


@notices_bp.route('/<notice_id>', methods=['GET'])
def get_notice(notice_id):
    """
    Get a single notice by ID
    """
    try:
        notices_collection = get_collection(Collections.NOTICES)
        notice = notices_collection.find_one({'_id': ObjectId(notice_id), 'is_active': True})
        
        if not notice:
            return jsonify({'error': 'Notice not found'}), 404
        
        # Increment views
        notices_collection.update_one({'_id': ObjectId(notice_id)}, {'$inc': {'views': 1}})
        
        return jsonify({'notice': NoticeModel.to_dict(notice)}), 200
    
    except Exception as e:
        print(f"Get notice error: {e}")
        return jsonify({'error': 'Failed to get notice'}), 500


@notices_bp.route('/', methods=['POST'])
@require_auth
def create_notice():
    """
    Create a new notice
    Requires authentication
    """
    try:
        data = request.get_json()
        
        # Validate required fields
        if not data.get('title') or not data.get('content'):
            return jsonify({'error': 'Title and content are required'}), 400
        
        # Create notice document
        notice_doc = NoticeModel.create_notice(
            title=data['title'],
            content=data['content'],
            faculty_id=request.user.get('user_id'),
            priority=data.get('priority', 'normal')
        )
        
        # Insert into database
        notices_collection = get_collection(Collections.NOTICES)
        result = notices_collection.insert_one(notice_doc)
        
        notice_doc['_id'] = result.inserted_id
        
        # Create notification for new notice
        create_notification(
            title='New Notice Posted',
            message=f'A new notice "{data.get("title", "")}" has been posted',
            notification_type='upload'
        )
        
        return jsonify({
            'message': 'Notice created successfully',
            'notice': NoticeModel.to_dict(notice_doc)
        }), 201
    
    except Exception as e:
        print(f"Create notice error: {e}")
        return jsonify({'error': 'Failed to create notice'}), 500


@notices_bp.route('/<notice_id>', methods=['PUT'])
@require_auth
def update_notice(notice_id):
    """
    Update a notice
    Requires authentication
    """
    try:
        data = request.get_json()
        
        # Build update document
        update_data = {
            'updated_at': datetime.utcnow()
        }
        
        if data.get('title'):
            update_data['title'] = data['title']
        
        if data.get('content'):
            update_data['content'] = data['content']
        
        if data.get('priority'):
            update_data['priority'] = data['priority']
        
        # Update in database
        notices_collection = get_collection(Collections.NOTICES)
        result = notices_collection.update_one(
            {'_id': ObjectId(notice_id)},
            {'$set': update_data}
        )
        
        if result.matched_count == 0:
            return jsonify({'error': 'Notice not found'}), 404
        
        # Get updated notice
        notice = notices_collection.find_one({'_id': ObjectId(notice_id)})
        
        return jsonify({
            'message': 'Notice updated successfully',
            'notice': NoticeModel.to_dict(notice)
        }), 200
    
    except Exception as e:
        print(f"Update notice error: {e}")
        return jsonify({'error': 'Failed to update notice'}), 500


@notices_bp.route('/<notice_id>', methods=['DELETE'])
@require_auth
def delete_notice(notice_id):
    """
    Delete (deactivate) a notice
    Requires authentication
    """
    try:
        notices_collection = get_collection(Collections.NOTICES)
        
        # Soft delete - set is_active to False
        result = notices_collection.update_one(
            {'_id': ObjectId(notice_id)},
            {'$set': {'is_active': False, 'deleted_at': datetime.utcnow()}}
        )
        
        if result.matched_count == 0:
            return jsonify({'error': 'Notice not found'}), 404
        
        return jsonify({'message': 'Notice deleted successfully'}), 200
    
    except Exception as e:
        print(f"Delete notice error: {e}")
        return jsonify({'error': 'Failed to delete notice'}), 500
