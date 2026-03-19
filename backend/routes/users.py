"""
User management routes for SRIMCA AI Backend
Handles user profile operations
"""

from flask import Blueprint, request, jsonify
from bson import ObjectId
from datetime import datetime

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


@users_bp.route('/faculty/visitor-inquiries', methods=['GET'], endpoint='get_faculty_visitor_inquiries')
@require_auth
def get_faculty_visitor_inquiries():
    """
    Get visitor inquiries for faculty view
    Requires authentication (faculty/admin)
    """
    try:
        current_role = request.user.get('role', '')
        if current_role not in ['faculty', 'admin']:
            return jsonify({'error': 'Only faculty/admin can view visitor inquiries'}), 403

        limit = int(request.args.get('limit', 100))
        users_collection = get_collection(Collections.USERS)
        visitors_collection = get_collection(Collections.VISITORS)

        inquiries = []

        # Primary source: visitor registrations in users collection
        visitor_users = list(
            users_collection.find({'role': 'visitor'})
            .sort('created_at', -1)
            .limit(limit)
        )
        for user in visitor_users:
            inquiries.append({
                '_id': str(user.get('_id', '')),
                'name': user.get('name', ''),
                'email': user.get('email', ''),
                'phone': user.get('mobile', user.get('phone', '')),
                'purpose': user.get('purpose', ''),
                'question': user.get('visitor_question', user.get('purpose', '')),
                'visit_date': user.get('visit_date', ''),
                'status': user.get('approval_status', user.get('status', 'pending')),
                'faculty_reply': user.get('faculty_reply', ''),
                'updated_at': user.get('updated_at').isoformat() if user.get('updated_at') else None,
                'created_at': user.get('created_at').isoformat() if user.get('created_at') else None,
            })

        # Secondary source: legacy visitors collection
        existing_emails = {i.get('email', '').lower() for i in inquiries if i.get('email')}
        legacy_visitors = list(
            visitors_collection.find()
            .sort('created_at', -1)
            .limit(limit)
        )
        for visitor in legacy_visitors:
            email = visitor.get('email', '')
            if email and email.lower() in existing_emails:
                continue
            inquiries.append({
                '_id': str(visitor.get('_id', '')),
                'name': visitor.get('name', ''),
                'email': email,
                'phone': visitor.get('phone', ''),
                'purpose': visitor.get('purpose', ''),
                'question': visitor.get('question', visitor.get('purpose', '')),
                'visit_date': visitor.get('visit_date', ''),
                'status': visitor.get('status', 'pending'),
                'faculty_reply': visitor.get('faculty_reply', ''),
                'updated_at': visitor.get('updated_at').isoformat() if visitor.get('updated_at') else None,
                'created_at': visitor.get('created_at').isoformat() if visitor.get('created_at') else None,
            })

        inquiries.sort(key=lambda x: x.get('created_at') or '', reverse=True)

        return jsonify({'inquiries': inquiries, 'count': len(inquiries)}), 200
    except Exception as e:
        print(f"Get faculty visitor inquiries error: {e}")
        return jsonify({'error': 'Failed to get visitor inquiries'}), 500


@users_bp.route('/faculty/visitor-inquiries/<visitor_id>/respond', methods=['PUT'], endpoint='respond_faculty_visitor_inquiry')
@require_auth
def respond_faculty_visitor_inquiry(visitor_id):
    """
    Update visitor inquiry status and faculty response
    Requires authentication (faculty/admin)
    """
    try:
        current_role = request.user.get('role', '')
        if current_role not in ['faculty', 'admin']:
            return jsonify({'error': 'Only faculty/admin can respond to visitor inquiries'}), 403

        data = request.get_json() or {}
        new_status = data.get('status', '').strip().lower()
        faculty_reply = data.get('faculty_reply', '').strip()
        if new_status not in ['approved', 'rejected', 'pending', 'completed']:
            return jsonify({'error': 'Invalid status'}), 400

        update_doc = {
            'updated_at': datetime.utcnow(),
            'status': new_status,
            'approval_status': new_status,
            'faculty_reply': faculty_reply,
            'faculty_replied_by': request.user.get('name', ''),
            'faculty_replied_by_id': request.user.get('user_id', ''),
        }

        users_collection = get_collection(Collections.USERS)
        visitors_collection = get_collection(Collections.VISITORS)

        users_result = users_collection.update_one(
            {'_id': ObjectId(visitor_id), 'role': 'visitor'},
            {'$set': update_doc}
        )
        visitors_result = visitors_collection.update_one(
            {'_id': ObjectId(visitor_id)},
            {'$set': update_doc}
        )

        if users_result.matched_count == 0 and visitors_result.matched_count == 0:
            return jsonify({'error': 'Visitor inquiry not found'}), 404

        return jsonify({'message': 'Visitor inquiry updated successfully'}), 200
    except Exception as e:
        print(f"Respond faculty visitor inquiry error: {e}")
        return jsonify({'error': 'Failed to update visitor inquiry'}), 500
