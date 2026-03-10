"""
Authentication routes for SRIMCA AI Backend
Handles user login, registration, and JWT token generation
"""

from flask import Blueprint, request, jsonify
import bcrypt
import jwt
from datetime import datetime, timedelta
from bson import ObjectId

from database import get_collection, Collections
from models import UserModel
from config import get_config
from notification_helper import create_notification

# Create auth blueprint
auth_bp = Blueprint('auth', __name__, url_prefix='/api')


def generate_jwt_token(user_doc: dict) -> str:
    """
    Generate a JWT token for the authenticated user
    """
    config = get_config()
    
    payload = {
        'user_id': str(user_doc.get('_id')),
        'email': user_doc.get('email'),
        'role': user_doc.get('role'),
        'name': user_doc.get('name'),
        'exp': datetime.utcnow() + timedelta(hours=config.JWT_EXPIRATION_HOURS),
        'iat': datetime.utcnow()
    }
    
    token = jwt.encode(payload, config.JWT_SECRET_KEY, algorithm='HS256')
    return token


def verify_jwt_token(token: str) -> dict:
    """
    Verify and decode a JWT token
    Returns the payload if valid, None otherwise
    """
    config = get_config()
    
    try:
        payload = jwt.decode(token, config.JWT_SECRET_KEY, algorithms=['HS256'])
        return payload
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None


@auth_bp.route('/register', methods=['POST'], endpoint='register')
def register():
    """
    Register a new user (student or visitor)
    Student fields: name, email, password, role, mobile, enrollment, dob, semester, department
    Visitor fields: name, email, password, role, mobile, purpose
    """
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['name', 'email', 'password', 'role']
        for field in required_fields:
            if field not in data or not data[field]:
                return jsonify({'error': f'{field} is required'}), 400
        
        name = data['name'].strip()
        email = data['email'].strip().lower()
        password = data['password']
        role = data.get('role', 'student').lower()
        mobile = data.get('mobile', '').strip()
        
        # For students, get academic fields
        enrollment = data.get('enrollment', '').strip()
        dob = data.get('dob', '').strip()
        semester = data.get('semester', '').strip()
        department = data.get('department', '').strip()
        
# For visitors, get purpose
        purpose = data.get('purpose', '').strip()
        
        # For faculty, get professional fields
        designation = data.get('designation', '').strip()
        
        # Validate based on role
        if role == 'student':
            if not mobile:
                return jsonify({'error': 'Mobile number is required for students'}), 400
            if not enrollment:
                return jsonify({'error': 'Enrollment number is required for students'}), 400
            if not dob:
                return jsonify({'error': 'Date of birth is required for students'}), 400
            if not semester:
                return jsonify({'error': 'Semester is required for students'}), 400
            if not department:
                return jsonify({'error': 'Department is required for students'}), 400
        elif role == 'faculty':
            if not mobile:
                return jsonify({'error': 'Mobile number is required for faculty'}), 400
            if not department:
                return jsonify({'error': 'Department is required for faculty'}), 400
            if not designation:
                return jsonify({'error': 'Designation is required for faculty'}), 400
        elif role == 'visitor':
            if not mobile:
                return jsonify({'error': 'Mobile number is required for visitors'}), 400
            if not purpose:
                return jsonify({'error': 'Purpose of visit is required for visitors'}), 400
        
        # Validate role
        valid_roles = ['student', 'faculty', 'visitor', 'admin']
        if role not in valid_roles:
            return jsonify({'error': f'Invalid role. Must be one of: {valid_roles}'}), 400
        
        # Validate password length
        if len(password) < 6:
            return jsonify({'error': 'Password must be at least 6 characters'}), 400
        
        # Get users collection
        users = get_collection(Collections.USERS)
        
        # Check if user already exists
        existing_user = users.find_one({'email': email})
        if existing_user:
            return jsonify({'error': 'Email already registered'}), 409
        
        # Check enrollment number for students
        if role == 'student' and enrollment:
            existing_enrollment = users.find_one({'enrollment': enrollment})
            if existing_enrollment:
                return jsonify({'error': 'Enrollment number already registered'}), 409
        
        # Hash password
        hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
        
        # Create user document with basic fields
        user_doc = UserModel.create_user(
            name=name,
            email=email,
            password=hashed_password.decode('utf-8'),
            role=role
        )
        
        # Add common fields
        user_doc['mobile'] = mobile
        
        # Add role-specific fields
        if role == 'student':
            user_doc['semester'] = semester
            user_doc['department'] = department
            user_doc['enrollment'] = enrollment
            user_doc['dob'] = dob
        elif role == 'faculty':
            user_doc['department'] = department
            user_doc['designation'] = designation
        elif role == 'visitor':
            user_doc['purpose'] = purpose
            user_doc['visit_date'] = datetime.utcnow().isoformat()
            user_doc['approval_status'] = 'pending'
        
        # Insert user into database
        result = users.insert_one(user_doc)
        
        # Create notification for new user registration
        create_notification(
            title='New User Registered',
            message=f'{name} ({role}) has registered with email {email}',
            notification_type='user_register'
        )
        
        # Generate token
        user_doc['_id'] = result.inserted_id
        token = generate_jwt_token(user_doc)
        
        # Return success response
        return jsonify({
            'message': 'Registration successful',
            'token': token,
            'user': UserModel.to_dict(user_doc)
        }), 201
    
    except Exception as e:
        print(f"Registration error: {e}")
        return jsonify({'error': 'Registration failed'}), 500


@auth_bp.route('/login', methods=['POST'], endpoint='login')
def login():
    """
    Login user
    Expected JSON: { "email": "", "password": "" }
    """
    try:
        data = request.get_json()
        
        # Validate required fields
        if not data.get('email') or not data.get('password'):
            return jsonify({'error': 'Email and password are required'}), 400
        
        email = data['email'].strip().lower()
        password = data['password']
        
        # Get users collection
        users = get_collection(Collections.USERS)
        
        # Find user by email
        user_doc = users.find_one({'email': email})
        
        if not user_doc:
            return jsonify({'error': 'Invalid email or password'}), 401
        
        # Check if user is active
        if not user_doc.get('is_active', True):
            return jsonify({'error': 'Account is deactivated'}), 401
        
        # Verify password
        stored_password = user_doc.get('password', '')
        
        # Handle both string and bytes password storage
        if isinstance(stored_password, str):
            stored_password = stored_password.encode('utf-8')
        
        try:
            if not bcrypt.checkpw(password.encode('utf-8'), stored_password):
                return jsonify({'error': 'Invalid email or password'}), 401
        except Exception as e:
            print(f"Password verification error: {e}")
            return jsonify({'error': 'Invalid email or password'}), 401
        
        # Update last login
        users.update_one(
            {'_id': user_doc['_id']},
            {'$set': {'last_login': datetime.utcnow()}}
        )
        
        # Create notification for user login
        create_notification(
            title='User Login',
            message=f'{user_doc.get("name", "A user")} ({user_doc.get("role", "user")}) has logged in',
            notification_type='user_login'
        )
        
        # Generate token
        token = generate_jwt_token(user_doc)
        
        # Return success response
        return jsonify({
            'message': 'Login successful',
            'token': token,
            'user': UserModel.to_dict(user_doc)
        }), 200
    
    except Exception as e:
        print(f"Login error: {e}")
        return jsonify({'error': 'Login failed'}), 500


@auth_bp.route('/verify', methods=['GET'], endpoint='verify_token')
def verify_token():
    """
    Verify JWT token
    Expects Authorization header with Bearer token
    """
    auth_header = request.headers.get('Authorization')
    
    if not auth_header:
        return jsonify({'error': 'No authorization header'}), 401
    
    parts = auth_header.split()
    if len(parts) != 2 or parts[0].lower() != 'bearer':
        return jsonify({'error': 'Invalid authorization header'}), 401
    
    token = parts[1]
    payload = verify_jwt_token(token)
    
    if payload is None:
        return jsonify({'error': 'Invalid or expired token'}), 401
    
    return jsonify({
        'valid': True,
        'user': payload
    }), 200


@auth_bp.route('/refresh', methods=['POST'], endpoint='refresh_token')
def refresh_token():
    """
    Refresh JWT token
    Expects Authorization header with Bearer token
    """
    auth_header = request.headers.get('Authorization')
    
    if not auth_header:
        return jsonify({'error': 'No authorization header'}), 401
    
    parts = auth_header.split()
    if len(parts) != 2 or parts[0].lower() != 'bearer':
        return jsonify({'error': 'Invalid authorization header'}), 401
    
    token = parts[1]
    payload = verify_jwt_token(token)
    
    if payload is None:
        return jsonify({'error': 'Invalid or expired token'}), 401
    
    # Get fresh user data
    users = get_collection(Collections.USERS)
    user_doc = users.find_one({'_id': ObjectId(payload['user_id'])})
    
    if not user_doc:
        return jsonify({'error': 'User not found'}), 404
    
    # Generate new token
    new_token = generate_jwt_token(user_doc)
    
    return jsonify({
        'token': new_token,
        'user': UserModel.to_dict(user_doc)
    }), 200


@auth_bp.route('/change-password', methods=['POST'], endpoint='change_password')
def change_password():
    """
    Change user password
    Expects JSON: { "current_password": "", "new_password": "" }
    Requires Authorization header
    """
    auth_header = request.headers.get('Authorization')
    
    if not auth_header:
        return jsonify({'error': 'No authorization header'}), 401
    
    parts = auth_header.split()
    if len(parts) != 2 or parts[0].lower() != 'bearer':
        return jsonify({'error': 'Invalid authorization header'}), 401
    
    token = parts[1]
    payload = verify_jwt_token(token)
    
    if payload is None:
        return jsonify({'error': 'Invalid or expired token'}), 401
    
    try:
        data = request.get_json()
        
        if not data.get('current_password') or not data.get('new_password'):
            return jsonify({'error': 'Current and new password are required'}), 400
        
        if len(data['new_password']) < 6:
            return jsonify({'error': 'New password must be at least 6 characters'}), 400
        
        # Get user from database
        users = get_collection(Collections.USERS)
        user_doc = users.find_one({'_id': ObjectId(payload['user_id'])})
        
        if not user_doc:
            return jsonify({'error': 'User not found'}), 404
        
        # Verify current password
        stored_password = user_doc.get('password', '').encode('utf-8')
        if not bcrypt.checkpw(data['current_password'].encode('utf-8'), stored_password):
            return jsonify({'error': 'Current password is incorrect'}), 401
        
        # Hash new password
        hashed_new_password = bcrypt.hashpw(data['new_password'].encode('utf-8'), bcrypt.gensalt())
        
        # Update password
        users.update_one(
            {'_id': user_doc['_id']},
            {'$set': {'password': hashed_new_password.decode('utf-8')}}
        )
        
        return jsonify({'message': 'Password changed successfully'}), 200
    
    except Exception as e:
        print(f"Change password error: {e}")
        return jsonify({'error': 'Failed to change password'}), 500
