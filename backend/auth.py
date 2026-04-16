"""
Authentication routes for SRIMCA AI Backend
Handles user login, registration, and JWT token generation

NORMALIZED DATABASE DESIGN:
- Users collection: Authentication only (name, email, password, role)
- User_Profiles collection: Personal info (phone, address) - linked by user_id
- Students collection: Student-specific data (semester, department, enrollment)
- Faculty collection: Faculty-specific data (department, designation)
"""

from flask import Blueprint, request, jsonify
import bcrypt
import jwt
from datetime import datetime, timedelta
from bson import ObjectId
import hashlib
import os
import random
import smtplib
from email.mime.text import MIMEText

from database import get_collection, Collections
from models import UserModel
from config import get_config
from notification_helper import create_notification  # Optional: Enable if needed
from firebase import get_firebase_app
from firebase_admin import auth as firebase_auth

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


def _generate_otp() -> str:
    """Generate a 6-digit OTP."""
    return f"{random.randint(100000, 999999)}"


def _hash_otp(otp: str) -> str:
    """Hash OTP before storing in DB."""
    return hashlib.sha256(otp.encode("utf-8")).hexdigest()


def _send_registration_otp_email(email: str, otp: str, name: str = "") -> tuple[bool, str]:
    """Send OTP email using SMTP credentials from environment."""
    sender_email = os.getenv("SMTP_SENDER_EMAIL", "").strip()
    sender_password = os.getenv("SMTP_SENDER_PASSWORD", "").strip()
    smtp_host = os.getenv("SMTP_HOST", "smtp.gmail.com").strip()
    smtp_port = int(os.getenv("SMTP_PORT", "587"))

    if not sender_email or not sender_password:
        return False, "Email service not configured on server"

    greeting_name = name.strip() or "User"
    msg = MIMEText(
        (
            f"Hello {greeting_name},\n\n"
            f"Your SRIMCA AI registration OTP is: {otp}\n\n"
            "This OTP will expire in 10 minutes.\n"
            "If you did not request this, please ignore this email.\n\n"
            "Regards,\nSRIMCA AI Team"
        ),
        "html",
    )
    msg["Subject"] = "SRIMCA AI Registration OTP"
    msg["From"] = sender_email
    msg["To"] = email

    try:
        with smtplib.SMTP(smtp_host, smtp_port) as server:
            server.starttls()
            server.login(sender_email, sender_password)
            server.send_message(msg)
        return True, "OTP sent successfully"
    except Exception as e:
        print(f"OTP email sending error: {e}")
        return False, "Failed to send OTP email"


def _send_verification_email(email: str, verification_link: str, name: str = "") -> tuple[bool, str]:
    """Send Firebase email verification link using SMTP credentials from environment."""
    sender_email = os.getenv("SMTP_SENDER_EMAIL", "").strip()
    sender_password = os.getenv("SMTP_SENDER_PASSWORD", "").strip()
    smtp_host = os.getenv("SMTP_HOST", "smtp.gmail.com").strip()
    smtp_port = int(os.getenv("SMTP_PORT", "587"))

    if not sender_email or not sender_password:
        return False, "Email service not configured on server"

    greeting_name = name.strip() or "User"
    msg = MIMEText(
        (
            f"Hello {greeting_name},\n\n"
            "Welcome to SRIMCA AI.\n"
            "Please verify your email by clicking the link below:\n\n"
            f"{verification_link}\n\n"
            "If you did not create this account, you can ignore this email.\n\n"
            "Regards,\nSRIMCA AI Team"
        ),
        "plain",
    )
    msg["Subject"] = "Verify your SRIMCA AI email"
    msg["From"] = sender_email
    msg["To"] = email

    try:
        with smtplib.SMTP(smtp_host, smtp_port) as server:
            server.starttls()
            server.login(sender_email, sender_password)
            server.send_message(msg)
        return True, "Verification email sent successfully"
    except Exception as e:
        print(f"Verification email sending error: {e}")
        return False, "Failed to send verification email"


def _get_firebase_user_by_email(email: str):
    """Fetch Firebase user by email if Firebase is enabled."""
    app = get_firebase_app()
    if app is None:
        return None
    try:
        return firebase_auth.get_user_by_email(email, app=app)
    except firebase_auth.UserNotFoundError:
        return None
    except Exception as e:
        print(f"Firebase get_user_by_email error: {e}")
        return None


@auth_bp.route('/send-registration-otp', methods=['POST'])
def send_registration_otp():
    """
    Send OTP to email before registration.
    Expected JSON: { "email": "", "name": "" }
    """
    try:
        data = request.get_json() or {}
        email = (data.get('email') or '').strip().lower()
        name = (data.get('name') or '').strip()

        if not email:
            return jsonify({'error': 'Email is required'}), 400

        users = get_collection(Collections.USERS)
        if users.find_one({'email': email}):
            return jsonify({'error': 'Email already registered'}), 409

        otp = _generate_otp()
        otp_codes = get_collection(Collections.SYSTEM_META)
        expires_at = datetime.utcnow() + timedelta(minutes=10)

        otp_codes.update_one(
            {'type': 'registration_otp', 'email': email},
            {'$set': {
                'type': 'registration_otp',
                'email': email,
                'otp_hash': _hash_otp(otp),
                'expires_at': expires_at,
                'verified': False,
                'updated_at': datetime.utcnow(),
            }},
            upsert=True
        )

        sent, message = _send_registration_otp_email(email=email, otp=otp, name=name)
        if not sent:
            return jsonify({'error': message}), 500

        return jsonify({'message': message}), 200
    except Exception as e:
        print(f"Send registration OTP error: {e}")
        return jsonify({'error': 'Failed to send OTP'}), 500


@auth_bp.route('/verify-registration-otp', methods=['POST'])
def verify_registration_otp():
    """
    Verify registration OTP.
    Expected JSON: { "email": "", "otp": "" }
    """
    try:
        data = request.get_json() or {}
        email = (data.get('email') or '').strip().lower()
        otp = (data.get('otp') or '').strip()

        if not email or not otp:
            return jsonify({'error': 'Email and OTP are required'}), 400

        otp_codes = get_collection(Collections.SYSTEM_META)
        otp_doc = otp_codes.find_one({'type': 'registration_otp', 'email': email})
        if not otp_doc:
            return jsonify({'error': 'OTP not found. Please request a new OTP'}), 404

        expires_at = otp_doc.get('expires_at')
        if not expires_at or datetime.utcnow() > expires_at:
            return jsonify({'error': 'OTP expired. Please request a new OTP'}), 400

        if otp_doc.get('otp_hash') != _hash_otp(otp):
            return jsonify({'error': 'Invalid OTP'}), 400

        otp_codes.update_one(
            {'_id': otp_doc['_id']},
            {'$set': {'verified': True, 'verified_at': datetime.utcnow()}}
        )

        return jsonify({'message': 'OTP verified successfully'}), 200
    except Exception as e:
        print(f"Verify registration OTP error: {e}")
        return jsonify({'error': 'Failed to verify OTP'}), 500


@auth_bp.route('/register', methods=['POST'])
def register():
    """
    Register a new user (student, faculty, or visitor)
    
    NORMALIZED: This function now inserts data into multiple collections:
    - Users: Authentication data (name, email, password, role)
    - User_Profiles: Personal info (phone, address)
    - Students: Academic data (semester, department, enrollment)
    - Faculty: Professional data (department, designation)
    
    Student fields: name, email, password, role, mobile, enrollment, dob, semester, department
    Faculty fields: name, email, password, role, mobile, department, designation
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
        address = data.get('address', '').strip()
        
        # For students, get academic fields
        enrollment = data.get('enrollment', '').strip()
        dob = data.get('dob', '').strip()
        semester = data.get('semester', '').strip()
        department = data.get('department', '').strip()
        
        # For faculty, get professional fields
        designation = data.get('designation', '').strip()
        
        # For visitors, get purpose
        purpose = data.get('purpose', '').strip()
        
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
        
        # Get users collection only (store all data in single collection)
        users = get_collection(Collections.USERS)
        
        # Check if user already exists
        existing_user = users.find_one({'email': email})
        if existing_user:
            return jsonify({'error': 'Email already registered'}), 409

        # Require OTP verification before allowing registration
        otp_codes = get_collection(Collections.SYSTEM_META)
        otp_doc = otp_codes.find_one({'type': 'registration_otp', 'email': email})
        if not otp_doc or not otp_doc.get('verified'):
            return jsonify({'error': 'Please verify OTP before registration'}), 400
        
        # Check enrollment number for students
        if role == 'student' and enrollment:
            existing_enrollment = users.find_one({'enrollment': enrollment})
            if existing_enrollment:
                return jsonify({'error': 'Enrollment number already registered'}), 409
        
        # Hash password
        hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
        
        # Create user document with ALL data in users collection
        user_doc = UserModel.create_user(
            name=name,
            email=email,
            password=hashed_password.decode('utf-8'),
            role=role
        )

        # Optional Firebase account + email verification link.
        # This runs only when Firebase Admin SDK is configured.
        firebase_app = get_firebase_app()
        if firebase_app is not None:
            firebase_user = _get_firebase_user_by_email(email)
            created_in_firebase = False
            if firebase_user is None:
                firebase_user = firebase_auth.create_user(
                    email=email,
                    password=password,
                    display_name=name,
                    app=firebase_app
                )
                created_in_firebase = True

            try:
                verification_link = firebase_auth.generate_email_verification_link(
                    email, 
                    app=firebase_app,
                    action_code_settings={
                        'url': 'https://srimca-ai-app-y828.onrender.com/email-verified',
                        'handle_code_in_app': True
                    }
                )
                sent, message = _send_verification_email(email=email, verification_link=verification_link, name=name)
                if not sent:
                    if created_in_firebase:
                        try:
                            firebase_auth.delete_user(firebase_user.uid, app=firebase_app)
                        except Exception as delete_err:
                            print(f"Failed to cleanup Firebase user after email send failure: {delete_err}")
                    return jsonify({'error': message}), 500
            except Exception as firebase_err:
                if created_in_firebase:
                    try:
                        firebase_auth.delete_user(firebase_user.uid, app=firebase_app)
                    except Exception as delete_err:
                        print(f"Failed to cleanup Firebase user after link generation failure: {delete_err}")
                print(f"Firebase verification setup error: {firebase_err}")
                return jsonify({'error': 'Failed to setup email verification'}), 500

            user_doc['firebase_uid'] = firebase_user.uid
            user_doc['email_verified'] = bool(firebase_user.email_verified)
            user_doc['verification_email_sent_at'] = datetime.utcnow()
        else:
            user_doc['email_verified'] = True
        
        # Add ALL fields to the user document (single collection)
        user_doc['mobile'] = mobile
        user_doc['address'] = address
        
        # Add student-specific fields
        if role == 'student':
            user_doc['enrollment'] = enrollment
            user_doc['dob'] = dob
            user_doc['semester'] = semester
            user_doc['department'] = department
        
        # Add faculty-specific fields
        elif role == 'faculty':
            user_doc['department'] = department
            user_doc['designation'] = designation
        
        # Add visitor-specific fields
        elif role == 'visitor':
            user_doc['purpose'] = purpose
            user_doc['visit_date'] = datetime.utcnow().isoformat()
            user_doc['approval_status'] = 'pending'
        
        # Insert user into database (single collection)
        result = users.insert_one(user_doc)
        user_doc['_id'] = result.inserted_id
        
        # Faculty fields are already stored directly in users collection.
        # Keep registration single-write here to avoid dependency on a separate model.
        
        # NOTE: Removed notification on registration for performance
        # If you need registration notifications, enable separately
        
        # Generate token
        token = generate_jwt_token(user_doc)
        
        # Return success response (with backward compatible user data)
        otp_codes.delete_one({'type': 'registration_otp', 'email': email})
        return jsonify({
            'message': 'Registration successful',
            'token': token,
            'user': UserModel.to_dict(user_doc)
        }), 201

    except Exception as e:
        print(f"Registration error: {e}")
        return jsonify({'error': 'Registration failed'}), 500


@auth_bp.route('/login', methods=['POST'])
def login():
    """
    Login user
    Expected JSON: { "email": "", "password": "" }
    """
    try:
        data = request.get_json()
        # Debug (safe): helps identify whether the email matches a user record.
        try:
            print(f"LOGIN ATTEMPT: email={data.get('email', '')}")
        except Exception:
            print("LOGIN ATTEMPT: email=<unavailable>")
        
        # Validate required fields
        if not data.get('email') or not data.get('password'):
            return jsonify({'error': 'Email and password are required'}), 400
        
        email = data['email'].strip().lower()
        password = data['password']
        
        # Get users collection
        users = get_collection(Collections.USERS)
        
        # Find user by email
        user_doc = users.find_one({'email': email})
        print(f"USER FOUND: {user_doc is not None}")
        
        if not user_doc:
            return jsonify({'error': 'Invalid email or password'}), 401
        
        # Check if user is active
        if not user_doc.get('is_active', True):
            return jsonify({'error': 'Account is deactivated'}), 401

        # Enforce Firebase email verification when Firebase is configured.
        firebase_app = get_firebase_app()
        if firebase_app is not None:
            firebase_user = _get_firebase_user_by_email(email)
            if firebase_user and not firebase_user.email_verified:
                users.update_one(
                    {'_id': user_doc['_id']},
                    {'$set': {'email_verified': False}}
                )
                return jsonify({'error': 'Please verify your email before login'}), 403
            if firebase_user and firebase_user.email_verified and not user_doc.get('email_verified'):
                users.update_one(
                    {'_id': user_doc['_id']},
                    {'$set': {'email_verified': True}}
                )
        
        # Verify password
        stored_password = user_doc.get('password', '')
        # Debug (safe): print only a prefix, not the whole hash.
        if isinstance(stored_password, str) and len(stored_password) > 6:
            print(f"STORED PASSWORD HASH PREFIX: {stored_password[:6]}")
        else:
            print("STORED PASSWORD HASH PREFIX: <missing/unknown>")
        
        # Handle both string and bytes password storage
        if isinstance(stored_password, str):
            stored_password = stored_password.encode('utf-8')
        
        try:
            if not bcrypt.checkpw(password.encode('utf-8'), stored_password):
                return jsonify({'error': 'Invalid email or password'}), 401
        except Exception as e:
            print(f"Password verification error: {e}")
            return jsonify({'error': 'Invalid email or password'}), 401
        
        # Update last login (optimized - use update_one efficiently)
        users.update_one(
            {'_id': user_doc['_id']},
            {'$set': {'last_login': datetime.utcnow()}}
        )
        
        # NOTE: Removed notification creation on login for performance
        # If you want login notifications, enable them separately
        
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


@auth_bp.route('/verify', methods=['GET'])
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


@auth_bp.route('/refresh', methods=['POST'])
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


@auth_bp.route('/change-password', methods=['POST'])
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


@auth_bp.route('/resend-verification-email', methods=['POST'])
def resend_verification_email():
    """
    Resend Firebase verification email.
    Expected JSON: { "email": "" }
    """
    try:
        data = request.get_json() or {}
        email = (data.get('email') or '').strip().lower()
        if not email:
            return jsonify({'error': 'Email is required'}), 400

        users = get_collection(Collections.USERS)
        user_doc = users.find_one({'email': email})
        if not user_doc:
            return jsonify({'error': 'User not found'}), 404

        firebase_app = get_firebase_app()
        if firebase_app is None:
            return jsonify({'error': 'Firebase email verification is not enabled on server'}), 503

        firebase_user = _get_firebase_user_by_email(email)
        if firebase_user is None:
            return jsonify({'error': 'Firebase user not found for this email'}), 404
        
        # Rate limiting: 1 email per 60 seconds
        now = datetime.utcnow()
        last_sent = user_doc.get('last_verification_email_sent')
        if last_sent and (now - last_sent).seconds < 60:
            return jsonify({'error': 'Please wait 60 seconds before requesting again'}), 429
        
        if firebase_user.email_verified:
            users.update_one({'_id': user_doc['_id']}, {'$set': {'email_verified': True}})
            return jsonify({'message': 'Email already verified'}), 200

        verification_link = firebase_auth.generate_email_verification_link(
            email, 
            app=firebase_app,
            action_code_settings={
                'url': 'https://srimca-ai-app-y828.onrender.com/email-verified',
                'handle_code_in_app': True
            }
        )
        sent, message = _send_verification_email(
            email=email,
            verification_link=verification_link,
            name=user_doc.get('name', '')
        )
        if not sent:
            return jsonify({'error': message}), 500

        users.update_one(
            {'_id': user_doc['_id']},
            {'$set': {
                'verification_email_sent_at': datetime.utcnow(),
                'last_verification_email_sent': datetime.utcnow()
            }}
        )
        return jsonify({'message': message}), 200
    except Exception as e:
        print(f"Resend verification email error: {e}")
        return jsonify({'error': 'Failed to resend verification email'}), 500


@auth_bp.route('/email-verification-status', methods=['POST'])
def email_verification_status():
    """
    Check whether a user's Firebase email is verified.
    Expected JSON: { "email": "" }
    """
    try:
        data = request.get_json() or {}
        email = (data.get('email') or '').strip().lower()
        if not email:
            return jsonify({'error': 'Email is required'}), 400

        users = get_collection(Collections.USERS)
        user_doc = users.find_one({'email': email})
        if not user_doc:
            return jsonify({'error': 'User not found'}), 404

        firebase_app = get_firebase_app()
        if firebase_app is None:
            return jsonify({
                'email_verified': bool(user_doc.get('email_verified', True)),
                'source': 'local'
            }), 200

        firebase_user = _get_firebase_user_by_email(email)
        if firebase_user is None:
            return jsonify({'error': 'Firebase user not found for this email'}), 404

        verified = bool(firebase_user.email_verified)
        users.update_one({'_id': user_doc['_id']}, {'$set': {'email_verified': verified}})
        return jsonify({
            'email_verified': verified,
            'source': 'firebase'
        }), 200
    except Exception as e:
        print(f"Email verification status error: {e}")
        return jsonify({'error': 'Failed to check verification status'}), 500
