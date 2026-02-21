"""
Firebase Admin SDK Integration
Handles Firebase authentication and token verification
"""

import os
import json
import firebase_admin
from firebase_admin import credentials, auth
from flask import jsonify, request
from functools import wraps
from config import get_config

# Firebase admin instance
_firebase_app = None


def initialize_firebase():
    """
    Initialize Firebase Admin SDK
    Uses the service account JSON file directly
    """
    global _firebase_app
    
    # Check if Firebase is already initialized
    if _firebase_app is not None:
        return _firebase_app
    
    try:
        # Try to load from JSON file
        json_path = os.path.join(os.path.dirname(__file__), 'srimcaai-firebase-adminsdk-fbsvc-e50090f727.json')
        
        if os.path.exists(json_path):
            cred = credentials.Certificate(json_path)
            _firebase_app = firebase_admin.initialize_app(cred)
            print(f"✅ Firebase Admin SDK initialized from JSON file")
            return _firebase_app
        else:
            # Fall back to environment variables
            config = get_config()
            if not config.FIREBASE_PRIVATE_KEY or not config.FIREBASE_CLIENT_EMAIL:
                print("⚠️ Firebase credentials not found. Firebase auth will be disabled.")
                return None
            
            # Handle newlines in private key
            private_key = config.FIREBASE_PRIVATE_KEY
            if '\\n' in private_key:
                private_key = private_key.replace('\\n', '\n')
            
            cred_dict = {
                "type": "service_account",
                "project_id": config.FIREBASE_PROJECT_ID,
                "private_key": private_key,
                "client_email": config.FIREBASE_CLIENT_EMAIL,
                "token_uri": "https://oauth2.googleapis.com/token",
            }
            
            cred = credentials.Certificate(cred_dict)
            _firebase_app = firebase_admin.initialize_app(cred)
            print(f"✅ Firebase Admin SDK initialized for project: {config.FIREBASE_PROJECT_ID}")
            return _firebase_app
        
    except Exception as e:
        print(f"❌ Failed to initialize Firebase: {e}")
        return None


def get_firebase_app():
    """Get the Firebase app instance"""
    global _firebase_app
    
    if _firebase_app is None:
        initialize_firebase()
    
    return _firebase_app


def verify_firebase_token(id_token: str):
    """
    Verify a Firebase ID token
    Returns the decoded token if valid, None otherwise
    """
    try:
        app = get_firebase_app()
        if app is None:
            return None
        
        decoded_token = auth.verify_id_token(id_token, app=app)
        return decoded_token
    
    except auth.InvalidIdTokenError:
        print("Invalid Firebase ID token")
        return None
    except auth.ExpiredIdTokenError:
        print("Expired Firebase ID token")
        return None
    except Exception as e:
        print(f"Firebase token verification error: {e}")
        return None


def get_firebase_user(uid: str):
    """
    Get Firebase user by UID
    Returns user record if found, None otherwise
    """
    try:
        app = get_firebase_app()
        if app is None:
            return None
        
        user = auth.get_user(uid, app=app)
        return user
    
    except auth.UserNotFoundError:
        return None
    except Exception as e:
        print(f"Error getting Firebase user: {e}")
        return None


def create_custom_token(uid: str, additional_claims: dict = None):
    """
    Create a custom Firebase token
    Can be used for custom authentication flow
    """
    try:
        app = get_firebase_app()
        if app is None:
            return None
        
        custom_token = auth.create_custom_token(uid, app=app, additional_claims=additional_claims)
        return custom_token.decode('utf-8') if custom_token else None
    
    except Exception as e:
        print(f"Error creating custom token: {e}")
        return None


def require_firebase_auth(f):
    """
    Decorator to require Firebase authentication for Flask routes
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        # Get the ID token from the request header
        auth_header = request.headers.get('Authorization')
        
        if not auth_header:
            return jsonify({'error': 'No authorization header provided'}), 401
        
        # Check if it's a Bearer token
        parts = auth_header.split()
        if len(parts) != 2 or parts[0].lower() != 'bearer':
            return jsonify({'error': 'Invalid authorization header format'}), 401
        
        id_token = parts[1]
        
        # Verify the token
        decoded_token = verify_firebase_token(id_token)
        
        if decoded_token is None:
            return jsonify({'error': 'Invalid or expired token'}), 401
        
        # Add the decoded token to the request context
        request.firebase_user = decoded_token
        request.firebase_uid = decoded_token.get('uid')
        
        return f(*args, **kwargs)
    
    return decorated_function


def optional_firebase_auth(f):
    """
    Decorator for optional Firebase authentication
    If a valid token is provided, it will be available in request.firebase_user
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        auth_header = request.headers.get('Authorization')
        
        if auth_header:
            parts = auth_header.split()
            if len(parts) == 2 and parts[0].lower() == 'bearer':
                id_token = parts[1]
                decoded_token = verify_firebase_token(id_token)
                if decoded_token:
                    request.firebase_user = decoded_token
                    request.firebase_uid = decoded_token.get('uid')
                else:
                    request.firebase_user = None
                    request.firebase_uid = None
            else:
                request.firebase_user = None
                request.firebase_uid = None
        else:
            request.firebase_user = None
            request.firebase_uid = None
        
        return f(*args, **kwargs)
    
    return decorated_function


def get_user_by_email(email: str):
    """
    Get Firebase user by email
    Returns user record if found, None otherwise
    """
    try:
        app = get_firebase_app()
        if app is None:
            return None
        
        user = auth.get_user_by_email(email, app=app)
        return user
    
    except auth.UserNotFoundError:
        return None
    except Exception as e:
        print(f"Error getting user by email: {e}")
        return None


def is_firebase_enabled():
    """Check if Firebase is properly initialized"""
    return _firebase_app is not None
