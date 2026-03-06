"""
Admin routes for SRIMCA AI Backend
Handles admin-specific operations like user management by role
"""

from flask import Blueprint, request, jsonify
from bson import ObjectId
import bcrypt
import jwt
from datetime import datetime, timedelta
from database import get_collection, Collections
from auth import verify_jwt_token
from config import get_config

# Create admin blueprint
admin_bp = Blueprint('admin', __name__, url_prefix='/api/admin')


@admin_bp.route('/login', methods=['POST'])
def admin_login():
    """
    Admin login - returns token with admin role
    Expected JSON: { "email": "", "password": "" }
    """
    try:
        data = request.get_json()
        
        if not data.get('email') or not data.get('password'):
            return jsonify({'error': 'Email and password are required'}), 400
        
        email = data['email'].strip().lower()
        password = data['password']
        
        users_collection = get_collection(Collections.USERS)
        
        # Find admin user by email
        user = users_collection.find_one({'email': email, 'role': 'admin'})
        
        if not user:
            return jsonify({'error': 'Invalid admin credentials'}), 401
        
        # Check if user is active
        if not user.get('is_active', True):
            return jsonify({'error': 'Account is deactivated'}), 401
        
        # Verify password
        stored_password = user.get('password', '')
        if isinstance(stored_password, str):
            stored_password = stored_password.encode('utf-8')
        
        try:
            if not bcrypt.checkpw(password.encode('utf-8'), stored_password):
                return jsonify({'error': 'Invalid admin credentials'}), 401
        except Exception as e:
            print(f"Password verification error: {e}")
            return jsonify({'error': 'Invalid admin credentials'}), 401
        
        # Generate token
        config = get_config()
        
        payload = {
            'user_id': str(user.get('_id')),
            'email': user.get('email'),
            'role': 'admin',
            'name': user.get('name'),
            'exp': datetime.utcnow() + timedelta(hours=config.JWT_EXPIRATION_HOURS),
            'iat': datetime.utcnow()
        }
        
        token = jwt.encode(payload, config.JWT_SECRET_KEY, algorithm='HS256')
        
        return jsonify({
            'success': True,
            'token': token,
            'admin': {
                '_id': str(user.get('_id')),
                'name': user.get('name'),
                'email': user.get('email'),
                'role': 'admin'
            }
        }), 200
    
    except Exception as e:
        print(f"Admin login error: {e}")
        return jsonify({'error': 'Admin login failed'}), 500


def require_admin(f):
    """Decorator to require admin authentication"""
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
        
        # Check if user is admin
        if payload.get('role') != 'admin':
            return jsonify({'error': 'Admin access required'}), 403
        
        request.user = payload
        return f(*args, **kwargs)
    return decorated


@admin_bp.route('/users', methods=['GET'])
def get_users_by_role():
    """
    Get users filtered by role
    Query params: role (student, faculty, admin)
    """
    try:
        role = request.args.get('role', 'student').lower()
        users_collection = get_collection(Collections.USERS)
        
        users = list(users_collection.find({'role': role}))
        
        # Convert to dict (without password)
        result = []
        for user in users:
            result.append({
                '_id': str(user.get('_id', '')),
                'name': user.get('name', ''),
                'email': user.get('email', ''),
                'role': user.get('role', ''),
                'is_active': user.get('is_active', True),
                'created_at': user.get('created_at').isoformat() if user.get('created_at') else None,
                'last_login': user.get('last_login').isoformat() if user.get('last_login') else None,
                'profile': user.get('profile', {})
            })
        
        return jsonify({'users': result, 'count': len(result)}), 200
    
    except Exception as e:
        print(f"Get users error: {e}")
        return jsonify({'error': 'Failed to get users'}), 500


@admin_bp.route('/users/<user_id>', methods=['GET'])
def get_user(user_id):
    """Get a specific user by ID"""
    try:
        users_collection = get_collection(Collections.USERS)
        user = users_collection.find_one({'_id': ObjectId(user_id)})
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        return jsonify({
            'user': {
                '_id': str(user.get('_id', '')),
                'name': user.get('name', ''),
                'email': user.get('email', ''),
                'role': user.get('role', ''),
                'is_active': user.get('is_active', True),
                'created_at': user.get('created_at').isoformat() if user.get('created_at') else None,
                'last_login': user.get('last_login').isoformat() if user.get('last_login') else None,
                'profile': user.get('profile', {})
            }
        }), 200
    
    except Exception as e:
        print(f"Get user error: {e}")
        return jsonify({'error': 'Failed to get user'}), 500


@admin_bp.route('/users', methods=['POST'])
def create_user():
    """Create a new user"""
    try:
        data = request.get_json()
        
        if not data.get('name') or not data.get('email') or not data.get('password'):
            return jsonify({'error': 'Name, email and password are required'}), 400
        
        users_collection = get_collection(Collections.USERS)
        
        # Check if email already exists
        if users_collection.find_one({'email': data['email'].lower()}):
            return jsonify({'error': 'Email already exists'}), 400
        
        user_doc = {
            'name': data['name'],
            'email': data['email'].lower(),
            'password': data['password'],  # In production, hash this!
            'role': data.get('role', 'student').lower(),
            'created_at': datetime.utcnow(),
            'updated_at': datetime.utcnow(),
            'is_active': True,
            'last_login': None,
            'profile': data.get('profile', {
                'phone': '',
                'address': '',
                'semester': data.get('semester', ''),
                'department': data.get('department', ''),
                'enrollment_number': data.get('enrollment_number', '')
            })
        }
        
        result = users_collection.insert_one(user_doc)
        
        return jsonify({
            'message': 'User created successfully',
            'user_id': str(result.inserted_id)
        }), 201
    
    except Exception as e:
        print(f"Create user error: {e}")
        return jsonify({'error': 'Failed to create user'}), 500


@admin_bp.route('/users/<user_id>', methods=['PUT'])
def update_user(user_id):
    """Update a user"""
    try:
        data = request.get_json()
        users_collection = get_collection(Collections.USERS)
        
        # Build update document
        update_data = {'updated_at': datetime.utcnow()}
        
        if data.get('name'):
            update_data['name'] = data['name']
        
        if data.get('email'):
            update_data['email'] = data['email'].lower()
        
        if data.get('is_active') is not None:
            update_data['is_active'] = data['is_active']
        
        if data.get('profile'):
            update_data['profile'] = data['profile']
        
        result = users_collection.update_one(
            {'_id': ObjectId(user_id)},
            {'$set': update_data}
        )
        
        if result.matched_count == 0:
            return jsonify({'error': 'User not found'}), 404
        
        return jsonify({'message': 'User updated successfully'}), 200
    
    except Exception as e:
        print(f"Update user error: {e}")
        return jsonify({'error': 'Failed to update user'}), 500


@admin_bp.route('/users/<user_id>', methods=['DELETE'])
def delete_user(user_id):
    """Delete a user"""
    try:
        users_collection = get_collection(Collections.USERS)
        
        result = users_collection.delete_one({'_id': ObjectId(user_id)})
        
        if result.deleted_count == 0:
            return jsonify({'error': 'User not found'}), 404
        
        return jsonify({'message': 'User deleted successfully'}), 200
    
    except Exception as e:
        print(f"Delete user error: {e}")
        return jsonify({'error': 'Failed to delete user'}), 500


@admin_bp.route('/visitors', methods=['GET'])
def get_visitors():
    """Get all visitors"""
    try:
        visitors_collection = get_collection(Collections.VISITORS)
        
        visitors = list(visitors_collection.find().sort('created_at', -1))
        
        result = []
        for visitor in visitors:
            result.append({
                '_id': str(visitor.get('_id', '')),
                'name': visitor.get('name', ''),
                'email': visitor.get('email', ''),
                'phone': visitor.get('phone', ''),
                'purpose': visitor.get('purpose', ''),
                'status': visitor.get('status', 'pending'),
                'visit_date': visitor.get('visit_date', ''),
                'entry_time': visitor.get('entry_time', ''),
                'exit_time': visitor.get('exit_time', ''),
                'created_at': visitor.get('created_at').isoformat() if visitor.get('created_at') else None
            })
        
        return jsonify({'visitors': result, 'count': len(result)}), 200
    
    except Exception as e:
        print(f"Get visitors error: {e}")
        return jsonify({'error': 'Failed to get visitors'}), 500


@admin_bp.route('/visitors/<visitor_id>', methods=['PUT'])
def update_visitor(visitor_id):
    """Update visitor status"""
    try:
        data = request.get_json()
        visitors_collection = get_collection(Collections.VISITORS)
        
        result = visitors_collection.update_one(
            {'_id': ObjectId(visitor_id)},
            {'$set': {'status': data.get('status', 'pending')}}
        )
        
        if result.matched_count == 0:
            return jsonify({'error': 'Visitor not found'}), 404
        
        return jsonify({'message': 'Visitor updated successfully'}), 200
    
    except Exception as e:
        print(f"Update visitor error: {e}")
        return jsonify({'error': 'Failed to update visitor'}), 500


# In-memory cache for stats (simple solution)
_stats_cache = {
    'data': None,
    'timestamp': 0
}
CACHE_DURATION = 30  # seconds


@admin_bp.route('/stats', methods=['GET'])
def get_stats():
    """Get admin dashboard statistics with caching"""
    import time
    try:
        current_time = time.time()
        
        # Check if cache is valid (less than CACHE_DURATION seconds old)
        if _stats_cache['data'] is not None and (current_time - _stats_cache['timestamp']) < CACHE_DURATION:
            return jsonify(_stats_cache['data']), 200
        
        # Get collections
        users_collection = get_collection(Collections.USERS)
        visitors_collection = get_collection(Collections.VISITORS)
        notices_collection = get_collection(Collections.NOTICES)
        materials_collection = get_collection(Collections.MATERIALS)
        
        # Optimized: Use single aggregation for users count by role
        user_role_counts = list(users_collection.aggregate([
            {'$group': {'_id': '$role', 'count': {'$sum': 1}}},
            {'$group': {'_id': None, 'roles': {'$push': {'role': '$_id', 'count': '$count'}}, 'total': {'$sum': '$count'}}}
        ]))
        
        # Parse role counts
        role_data = user_role_counts[0] if user_role_counts else {'roles': [], 'total': 0}
        roles = {r['role']: r['count'] for r in role_data.get('roles', [])}
        
        # Single count for active users
        active_users = users_collection.count_documents({'is_active': True})
        
        # Build stats with cached/default values
        stats = {
            'total_students': roles.get('student', 0),
            'total_faculty': roles.get('faculty', 0),
            'total_admin': roles.get('admin', 0),
            'total_users': role_data.get('total', 0),
            'total_visitors': visitors_collection.count_documents({}),
            'total_notices': notices_collection.count_documents({}),
            'total_materials': materials_collection.count_documents({}),
            'total_queries': 0,  # Simplified - can add if needed
            'active_users': active_users
        }
        
        # Cache the result
        _stats_cache['data'] = {'stats': stats}
        _stats_cache['timestamp'] = current_time
        
        return jsonify({'stats': stats}), 200
    
    except Exception as e:
        print(f"Get stats error: {e}")
        return jsonify({'error': 'Failed to get stats'}), 500
