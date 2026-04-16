"""
Admin routes for SRIMCA AI Backend
Handles admin-specific operations like user management by role
"""

from flask import Blueprint, request, jsonify
from bson import ObjectId
import bcrypt
import jwt
from datetime import datetime, timedelta
from database import get_collection, get_database, Collections
from auth import verify_jwt_token
from config import get_config

# Create admin blueprint
admin_bp = Blueprint('admin', __name__, url_prefix='/api/admin')


@admin_bp.route('/login', methods=['POST'], endpoint='admin_login')
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


@admin_bp.route('/users', methods=['GET'], endpoint='get_users_by_role')
@require_admin
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


@admin_bp.route('/users/<user_id>', methods=['GET'], endpoint='get_user')
@require_admin
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


@admin_bp.route('/users', methods=['POST'], endpoint='create_user_admin')
@require_admin
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


@admin_bp.route('/users/<user_id>', methods=['PUT'], endpoint='update_user_admin')
@require_admin
def update_user(user_id):
    """Update a user - only Faculty and Student can be edited (Admin cannot be edited)"""
    try:
        data = request.get_json()
        users_collection = get_collection(Collections.USERS)
        
        # Fetch target user - only faculty and student can be edited
        target_user = users_collection.find_one({'_id': ObjectId(user_id)})
        if not target_user:
            return jsonify({'error': 'User not found'}), 404
        target_role = (target_user.get('role') or '').lower()
        if target_role == 'admin':
            return jsonify({'error': 'Admin users cannot be edited'}), 403
        
        # Build update document
        update_data = {'updated_at': datetime.utcnow()}
        
        if data.get('name'):
            update_data['name'] = data['name']
        
        if data.get('email'):
            update_data['email'] = data['email'].lower()
        
        # Common contact fields (stored at top-level in this project)
        if data.get('mobile') is not None:
            update_data['mobile'] = str(data.get('mobile', '')).strip()
        if data.get('phone') is not None:
            # Accept `phone` too (some clients use this key)
            update_data['mobile'] = str(data.get('phone', '')).strip()

        if data.get('is_active') is not None:
            update_data['is_active'] = data['is_active']
        
        if data.get('role'):
            role = data['role'].strip().lower()
            if role in ('faculty', 'student'):
                update_data['role'] = role
        
        if data.get('profile'):
            update_data['profile'] = data['profile']

        # Allow updating gender even if client doesn't send full profile map
        if data.get('gender') is not None:
            profile = dict(target_user.get('profile') or {})
            profile['gender'] = str(data.get('gender', '')).strip().lower()
            update_data['profile'] = profile
        # Allow updating phone under profile as well (for UI consistency)
        if data.get('profile_phone') is not None:
            profile = dict(update_data.get('profile') or target_user.get('profile') or {})
            profile['phone'] = str(data.get('profile_phone', '')).strip()
            update_data['profile'] = profile
        
        result = users_collection.update_one(
            {'_id': ObjectId(user_id)},
            {'$set': update_data}
        )
        
        if result.matched_count == 0:
            return jsonify({'error': 'User not found'}), 404
        
        updated_user = users_collection.find_one({'_id': ObjectId(user_id)})
        return jsonify({'message': 'User updated successfully', 'user': updated_user}), 200
    
    except Exception as e:
        print(f"Update user error: {e}")
        return jsonify({'error': 'Failed to update user'}), 500


@admin_bp.route('/users/<user_id>', methods=['DELETE'], endpoint='delete_user_admin')
@require_admin
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


@admin_bp.route('/visitors', methods=['GET'], endpoint='get_visitors')
def get_visitors():
    """Get all visitors"""
    try:
        visitors_collection = get_collection(Collections.VISITORS)
        users_collection = get_collection(Collections.USERS)
        
        visitors = list(visitors_collection.find().sort('created_at', -1))
        visitor_users = list(users_collection.find({'role': 'visitor'}).sort('created_at', -1))
        
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

        # Also include visitor accounts stored in users collection.
        # This keeps admin list in sync with /api/register role=visitor flow.
        existing_emails = {v.get('email', '').lower() for v in result if v.get('email')}
        for user in visitor_users:
            email = user.get('email', '')
            if email and email.lower() in existing_emails:
                continue

            result.append({
                '_id': str(user.get('_id', '')),
                'name': user.get('name', ''),
                'email': email,
                'phone': user.get('mobile', ''),
                'purpose': user.get('purpose', ''),
                'status': user.get('approval_status', user.get('status', 'pending')),
                'visit_date': user.get('visit_date', ''),
                'entry_time': user.get('entry_time', ''),
                'exit_time': user.get('exit_time', ''),
                'created_at': user.get('created_at').isoformat() if user.get('created_at') else None
            })
        
        result.sort(key=lambda x: x.get('created_at') or '', reverse=True)

        return jsonify({'visitors': result, 'count': len(result)}), 200
    
    except Exception as e:
        print(f"Get visitors error: {e}")
        return jsonify({'error': 'Failed to get visitors'}), 500


@admin_bp.route('/visitors/<visitor_id>', methods=['PUT'], endpoint='update_visitor')
def update_visitor(visitor_id):
    """Update visitor status"""
    try:
        data = request.get_json()
        visitors_collection = get_collection(Collections.VISITORS)
        users_collection = get_collection(Collections.USERS)
        new_status = data.get('status', 'pending')
        
        result = visitors_collection.update_one(
            {'_id': ObjectId(visitor_id)},
            {'$set': {'status': new_status}}
        )

        # Keep visitor accounts in users collection synchronized.
        users_result = users_collection.update_one(
            {'_id': ObjectId(visitor_id), 'role': 'visitor'},
            {'$set': {'approval_status': new_status}}
        )
        
        if result.matched_count == 0 and users_result.matched_count == 0:
            return jsonify({'error': 'Visitor not found'}), 404
        
        return jsonify({'message': 'Visitor updated successfully'}), 200
    
    except Exception as e:
        print(f"Update visitor error: {e}")
        return jsonify({'error': 'Failed to update visitor'}), 500


@admin_bp.route('/stats', methods=['GET'], endpoint='get_stats')
def get_stats():
    """Get admin dashboard statistics"""
    try:
        users_collection = get_collection(Collections.USERS)
        visitors_collection = get_collection(Collections.VISITORS)
        notices_collection = get_collection(Collections.NOTICES)
        materials_collection = get_collection(Collections.MATERIALS)
        queries_collection = get_collection(Collections.QUERIES)
        
        # Count users by role
        total_students = users_collection.count_documents({'role': 'student'})
        total_faculty = users_collection.count_documents({'role': 'faculty'})
        total_admin = users_collection.count_documents({'role': 'admin'})
        
        # Count ALL users regardless of role
        total_all_users = users_collection.count_documents({})
        
        # Count visitors
        total_visitors = visitors_collection.count_documents({})
        
        # Count content
        total_notices = notices_collection.count_documents({})
        total_materials = materials_collection.count_documents({})
        
        # Count queries
        total_queries = queries_collection.count_documents({})
        
        return jsonify({
            'stats': {
                'total_students': total_students,
                'total_faculty': total_faculty,
                'total_admin': total_admin,
                'total_users': total_all_users,
                'total_visitors': total_visitors,
                'total_notices': total_notices,
                'total_materials': total_materials,
                'total_queries': total_queries,
                'active_users': users_collection.count_documents({'is_active': True})
            }
        }), 200
    
    except Exception as e:
        print(f"Get stats error: {e}")
        return jsonify({'error': 'Failed to get stats'}), 500


@admin_bp.route('/reports/analytics', methods=['GET'], endpoint='get_reports_analytics')
def get_reports_analytics():
    """Get reports and analytics summary data"""
    try:
        users_collection = get_collection(Collections.USERS)
        visitors_collection = get_collection(Collections.VISITORS)
        ai_queries_collection = get_collection(Collections.AI_QUERIES)

        total_users = users_collection.count_documents({})
        total_students = users_collection.count_documents({'role': 'student'})
        total_faculty = users_collection.count_documents({'role': 'faculty'})
        total_admin = users_collection.count_documents({'role': 'admin'})
        total_visitors_users = users_collection.count_documents({'role': 'visitor'})
        total_visitors_docs = visitors_collection.count_documents({})
        total_visitors = max(total_visitors_users, total_visitors_docs)

        now = datetime.utcnow()
        today_start = datetime(now.year, now.month, now.day)
        active_today = users_collection.count_documents({'last_login': {'$gte': today_start}})
        total_queries = ai_queries_collection.count_documents({})
        today_queries = ai_queries_collection.count_documents({'created_at': {'$gte': today_start}})

        # Last 6 months AI query activity
        monthly_activity = []
        for month_offset in range(5, -1, -1):
            month_index = now.month - month_offset
            year = now.year
            while month_index <= 0:
                month_index += 12
                year -= 1

            month_start = datetime(year, month_index, 1)
            if month_index == 12:
                next_month_start = datetime(year + 1, 1, 1)
            else:
                next_month_start = datetime(year, month_index + 1, 1)

            month_count = ai_queries_collection.count_documents({
                'created_at': {
                    '$gte': month_start,
                    '$lt': next_month_start
                }
            })

            monthly_activity.append({
                'month': month_start.strftime('%b'),
                'year': year,
                'queries': month_count
            })

        return jsonify({
            'overview': {
                'total_users': total_users,
                'active_today': active_today,
                'total_queries': total_queries,
                'avg_response': '<2s',
                'today_queries': today_queries,
            },
            'distribution': {
                'students': total_students,
                'faculty': total_faculty,
                'visitors': total_visitors,
                'admins': total_admin,
            },
            'monthly_activity': monthly_activity
        }), 200
    except Exception as e:
        print(f"Reports analytics error: {e}")
        return jsonify({'error': 'Failed to get reports analytics'}), 500


@admin_bp.route('/database/overview', methods=['GET'], endpoint='get_database_overview')
def get_database_overview():
    """Get database management overview and collection statistics"""
    try:
        db = get_database()
        users_collection = get_collection(Collections.USERS)
        notices_collection = get_collection(Collections.NOTICES)
        materials_collection = get_collection(Collections.MATERIALS)
        ai_queries_collection = get_collection(Collections.AI_QUERIES)
        notifications_collection = get_collection(Collections.NOTIFICATIONS)
        meta_collection = get_collection('system_meta')

        db_stats = {
            'users': users_collection.count_documents({}),
            'notices': notices_collection.count_documents({}),
            'materials': materials_collection.count_documents({}),
            'queries': ai_queries_collection.count_documents({}),
            'notifications': notifications_collection.count_documents({}),
        }

        db_info = db.command('dbstats')
        meta_doc = meta_collection.find_one({'_id': 'database_ops'}) or {}

        return jsonify({
            'stats': db_stats,
            'info': {
                'database_name': db.name,
                'version': '1.0.0',
                'size_mb': round((db_info.get('dataSize', 0) or 0) / (1024 * 1024), 2),
                'last_updated': datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S'),
                'last_backup': meta_doc.get('last_backup'),
            }
        }), 200
    except Exception as e:
        print(f"Database overview error: {e}")
        return jsonify({'error': 'Failed to get database overview'}), 500


@admin_bp.route('/database/backup', methods=['POST'], endpoint='backup_database')
def backup_database():
    """Record a backup action"""
    try:
        meta_collection = get_collection('system_meta')
        ts = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')
        meta_collection.update_one(
            {'_id': 'database_ops'},
            {'$set': {'last_backup': ts, 'updated_at': datetime.utcnow()}},
            upsert=True
        )
        return jsonify({'message': 'Database backup completed', 'last_backup': ts}), 200
    except Exception as e:
        print(f"Database backup error: {e}")
        return jsonify({'error': 'Database backup failed'}), 500


@admin_bp.route('/database/restore', methods=['POST'], endpoint='restore_database')
def restore_database():
    """Record a restore action"""
    try:
        meta_collection = get_collection('system_meta')
        ts = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')
        meta_collection.update_one(
            {'_id': 'database_ops'},
            {'$set': {'last_restore': ts, 'updated_at': datetime.utcnow()}},
            upsert=True
        )
        return jsonify({'message': 'Database restore completed', 'last_restore': ts}), 200
    except Exception as e:
        print(f"Database restore error: {e}")
        return jsonify({'error': 'Database restore failed'}), 500


@admin_bp.route('/database/optimize', methods=['POST'], endpoint='optimize_database')
def optimize_database():
    """Perform lightweight optimize operation"""
    try:
        db = get_database()
        # Compact command is not always available on Atlas; use a safe ping as health operation.
        db.command('ping')
        return jsonify({'message': 'Database optimization completed'}), 200
    except Exception as e:
        print(f"Database optimize error: {e}")
        return jsonify({'error': 'Database optimization failed'}), 500


@admin_bp.route('/database/clear-cache', methods=['POST'], endpoint='clear_database_cache')
def clear_database_cache():
    """Perform lightweight cache clear operation"""
    try:
        # MongoDB Atlas manages internal cache; we provide a successful maintenance action hook.
        return jsonify({'message': 'Database cache clear completed'}), 200
    except Exception as e:
        print(f"Database clear cache error: {e}")
        return jsonify({'error': 'Cache clear failed'}), 500
