"""
User management routes for SRIMCA AI Backend
Handles user profile operations
"""

from flask import Blueprint, request, jsonify
from bson import ObjectId

from database import get_collection, Collections
from models import UserModel
from auth import verify_jwt_token

# Create users blueprint
users_bp = Blueprint('users', __name__, url_prefix='/api/users')


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


@users_bp.route('/profile', methods=['GET'], endpoint='get_profile')
@require_auth
def get_profile():
    """
    Get current user's profile
    Requires authentication
    """
    try:
        users_collection = get_collection(Collections.USERS)
        user = users_collection.find_one({'_id': ObjectId(request.user['user_id'])})
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        return jsonify({'user': UserModel.to_dict(user)}), 200
    
    except Exception as e:
        print(f"Get profile error: {e}")
        return jsonify({'error': 'Failed to get profile'}), 500


@users_bp.route('/profile', methods=['PUT'], endpoint='update_profile')
@require_auth
def update_profile():
    """
    Update current user's profile
    Requires authentication
    """
    try:
        data = request.get_json()
        
        # Build update document
        update_data = {}
        
        if data.get('name'):
            update_data['name'] = data['name']
        
        if data.get('profile'):
            # Update profile fields
            update_data['profile'] = data['profile']
        
        if not update_data:
            return jsonify({'error': 'No fields to update'}), 400
        
        # Update in database
        users_collection = get_collection(Collections.USERS)
        result = users_collection.update_one(
            {'_id': ObjectId(request.user['user_id'])},
            {'$set': update_data}
        )
        
        if result.matched_count == 0:
            return jsonify({'error': 'User not found'}), 404
        
        # Get updated user
        user = users_collection.find_one({'_id': ObjectId(request.user['user_id'])})
        
        return jsonify({
            'message': 'Profile updated successfully',
            'user': UserModel.to_dict(user)
        }), 200
    
    except Exception as e:
        print(f"Update profile error: {e}")
        return jsonify({'error': 'Failed to update profile'}), 500


@users_bp.route('/<user_id>', methods=['GET'], endpoint='get_user_by_id')
@require_auth
def get_user(user_id):
    """
    Get a user by ID
    Requires authentication (admin/faculty only for viewing other users)
    """
    try:
        # Get current user's role
        current_role = request.user.get('role', '')
        
        # Students can only view their own profile
        if current_role == 'student' and user_id != request.user['user_id']:
            return jsonify({'error': 'Unauthorized'}), 403
        
        users_collection = get_collection(Collections.USERS)
        user = users_collection.find_one({'_id': ObjectId(user_id)})
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        return jsonify({'user': UserModel.to_dict(user)}), 200
    
    except Exception as e:
        print(f"Get user error: {e}")
        return jsonify({'error': 'Failed to get user'}), 500


@users_bp.route('/', methods=['GET'], endpoint='get_all_users')
@require_auth
def get_users():
    """
    Get all users (admin only)
    Requires authentication
    Query params: role, limit, offset
    """
    try:
        # Check if user is admin
        if request.user.get('role') != 'admin':
            return jsonify({'error': 'Only admins can view all users'}), 403
        
        # Parse query parameters
        limit = int(request.args.get('limit', 50))
        offset = int(request.args.get('offset', 0))
        role = request.args.get('role')
        
        # Build query
        query = {'is_active': True}
        
        if role:
            query['role'] = role
        
        # Get users from database
        users_collection = get_collection(Collections.USERS)
        users = list(users_collection.find(query)
                    .sort('created_at', -1)
                    .skip(offset)
                    .limit(limit))
        
        # Convert to dict
        result = [UserModel.to_dict(u) for u in users]
        
        return jsonify({
            'users': result,
            'count': len(result),
            'total': users_collection.count_documents(query)
        }), 200
    
    except Exception as e:
        print(f"Get users error: {e}")
        return jsonify({'error': 'Failed to get users'}), 500


@users_bp.route('/<user_id>/deactivate', methods=['POST'], endpoint='deactivate_user')
@require_auth
def deactivate_user(user_id):
    """
    Deactivate a user (admin only)
    Requires authentication
    """
    try:
        # Check if user is admin
        if request.user.get('role') != 'admin':
            return jsonify({'error': 'Only admins can deactivate users'}), 403
        
        users_collection = get_collection(Collections.USERS)
        
        # Deactivate user
        result = users_collection.update_one(
            {'_id': ObjectId(user_id)},
            {'$set': {'is_active': False}}
        )
        
        if result.matched_count == 0:
            return jsonify({'error': 'User not found'}), 404
        
        return jsonify({'message': 'User deactivated successfully'}), 200
    
    except Exception as e:
        print(f"Deactivate user error: {e}")
        return jsonify({'error': 'Failed to deactivate user'}), 500


@users_bp.route('/stats', methods=['GET'], endpoint='get_user_stats')
@require_auth
def get_admin_stats():
    """
    Get admin dashboard statistics
    Requires authentication (admin only)
    """
    try:
        # Check if user is admin
        if request.user.get('role') != 'admin':
            return jsonify({'error': 'Only admins can view stats'}), 403
        
        users_collection = get_collection(Collections.USERS)
        materials_collection = get_collection(Collections.MATERIALS)
        notices_collection = get_collection(Collections.NOTICES)
        assignments_collection = get_collection(Collections.ASSIGNMENTS)
        
        # Get counts
        total_users = users_collection.count_documents({'is_active': True})
        total_faculty = users_collection.count_documents({'is_active': True, 'role': 'faculty'})
        total_students = users_collection.count_documents({'is_active': True, 'role': 'student'})
        
        total_materials = materials_collection.count_documents({'is_active': True})
        pending_materials = materials_collection.count_documents({'is_active': True, 'status': 'pending'})
        approved_materials = materials_collection.count_documents({'is_active': True, 'status': 'approved'})
        
        total_notices = notices_collection.count_documents({'is_active': True})
        total_assignments = assignments_collection.count_documents({'is_active': True})
        
        return jsonify({
            'total_users': total_users,
            'total_faculty': total_faculty,
            'total_students': total_students,
            'total_uploads': total_materials,
            'pending_uploads': pending_materials,
            'approved_uploads': approved_materials,
            'total_notices': total_notices,
            'total_assignments': total_assignments,
        }), 200
    
    except Exception as e:
        print(f"Get admin stats error: {e}")
        return jsonify({'error': 'Failed to get stats'}), 500


@users_bp.route('/<user_id>/activate', methods=['POST'], endpoint='activate_user')
@require_auth
def activate_user(user_id):
    """
    Activate a user (admin only)
    Requires authentication
    """
    try:
        # Check if user is admin
        if request.user.get('role') != 'admin':
            return jsonify({'error': 'Only admins can activate users'}), 403
        
        users_collection = get_collection(Collections.USERS)
        
        # Activate user
        result = users_collection.update_one(
            {'_id': ObjectId(user_id)},
            {'$set': {'is_active': True}}
        )
        
        if result.matched_count == 0:
            return jsonify({'error': 'User not found'}), 404
        
        return jsonify({'message': 'User activated successfully'}), 200
    
    except Exception as e:
        print(f"Activate user error: {e}")
        return jsonify({'error': 'Failed to activate user'}), 500
