"""
Visitor management routes for SRIMCA AI
Handles visitor profile, history, QR generation, check-in
"""

from flask import Blueprint, request, jsonify, current_app
from functools import wraps
import qrcode
from io import BytesIO
import hashlib
import time
from bson import ObjectId
from database import get_collection, Collections
from models import VisitorLogModel, UserModel
from auth import verify_jwt_token
from config import get_config

visitor_bp = Blueprint('visitor', __name__, url_prefix='/api/visitor')

def require_visitor_or_admin(f):
    """Decorator: require visitor or admin role from JWT"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        auth_header = request.headers.get('Authorization')
        if not auth_header:
            return jsonify({'error': 'Authorization required'}), 401
        
        parts = auth_header.split()
        if len(parts) != 2 or parts[0].lower() != 'bearer':
            return jsonify({'error': 'Invalid authorization header'}), 401
        
        token = parts[1]
        payload = verify_jwt_token(token)
        if not payload:
            return jsonify({'error': 'Invalid or expired token'}), 401
        
        role = payload.get('role', '').lower()
        if role not in ['visitor', 'admin']:
            return jsonify({'error': 'Visitor or admin access only'}), 403
        
        request.visitor_user = payload
        return f(*args, **kwargs)
    return decorated_function

def generate_qr_token(visitor_id: str) -> str:
    """Generate short token for QR: vid + ts + secret"""
    config = get_config()
    secret = config.JWT_SECRET_KEY[:16]  # Use part of secret
    payload = f"{visitor_id}:{int(time.time())}:{secret}"
    return hashlib.sha256(payload.encode()).hexdigest()[:8]

@visitor_bp.route('/profile/<visitor_id>', methods=['GET', 'PATCH'])
@require_visitor_or_admin
def visitor_profile(visitor_id):
    users = get_collection(Collections.USERS)
    
    if request.method == 'GET':
        user_doc = users.find_one({'_id': ObjectId(visitor_id), 'role': 'visitor'})
        if not user_doc:
            return jsonify({'error': 'Visitor not found'}), 404
        
        return jsonify({
            'success': True,
            'profile': UserModel.to_dict(user_doc)
        })
    
    elif request.method == 'PATCH':
        # Admin can update, visitor can update own non-sensitive fields
        payload_user_id = request.visitor_user['user_id']
        role = request.visitor_user['role']
        
        data = request.get_json() or {}
        update_fields = {}
        
        if role == 'admin' or payload_user_id == visitor_id:
            allowed_fields = ['name', 'phone', 'purpose']
            for field in allowed_fields:
                if field in data:
                    update_fields[field] = data[field]
            
            if update_fields:
                result = users.update_one(
                    {'_id': ObjectId(visitor_id), 'role': 'visitor'},
                    {'$set': {**update_fields, 'updated_at': datetime.utcnow()}}
                )
                return jsonify({'success': result.modified_count > 0, 'message': 'Profile updated'})
        
        return jsonify({'error': 'No valid fields to update'}), 400

@visitor_bp.route('/history/<visitor_id>', methods=['GET'])
@require_visitor_or_admin
def visitor_history(visitor_id):
    logs = get_collection(Collections.VISITOR_LOGS)
    
    # Visitor sees own history, admin sees all
    query = {'visitor_id': visitor_id}
    logs_cursor = logs.find(query).sort('created_at', -1).limit(50)
    
    history = [VisitorLogModel.to_dict(log) for log in logs_cursor]
    
    return jsonify({
        'success': True,
        'history': history,
        'total': len(history)
    })

@visitor_bp.route('/qr/<visitor_id>', methods=['GET'])
@require_visitor_or_admin
def generate_visitor_qr(visitor_id):
    """Generate dynamic QR for visitor pass"""
    # Validate visitor exists
    users = get_collection(Collections.USERS)
    user_doc = users.find_one({'_id': ObjectId(visitor_id), 'role': 'visitor'})
    if not user_doc:
        return jsonify({'error': 'Visitor not found'}), 404
    
    # Generate QR payload URL
    token = generate_qr_token(visitor_id)
    base_url = current_app.config.get('FRONTEND_URL', 'https://srimcaai.web.app')
    qr_url = f"{base_url}/checkin?vid={visitor_id}&token={token}"
    
    # Create QR code
    qr = qrcode.QRCode(version=1, error_correction=qrcode.constants.ERROR_CORRECT_L, box_size=10, border=4)
    qr.add_data(qr_url)
    qr.make(fit=True)
    
    img = qr.make_image(fill_color="black", back_color="white")
    
    # Convert to base64
    img_buffer = BytesIO()
    img.save(img_buffer, 'PNG')
    img_str = base64.b64encode(img_buffer.getvalue()).decode()
    
    return jsonify({
        'success': True,
        'qr_url': qr_url,
        'qr_base64': f'data:image/png;base64,{img_str}',
        'token': token,
        'valid_until': int(time.time()) + 3600  # 1 hour
    })

@visitor_bp.route('/checkin', methods=['POST'])
def visitor_checkin():
    """Public endpoint for QR scan check-in (validate token)"""
    data = request.get_json() or {}
    visitor_id = data.get('vid')
    token = data.get('token')
    
    if not visitor_id or not token:
        return jsonify({'error': 'Missing visitor_id or token'}), 400
    
    # Validate token
    expected_token = generate_qr_token(visitor_id)
    if token != expected_token:
        return jsonify({'error': 'Invalid QR token'}), 400
    
    users = get_collection(Collections.USERS)
    user_doc = users.find_one({'_id': ObjectId(visitor_id), 'role': 'visitor'})
    if not user_doc:
        return jsonify({'error': 'Visitor not found'}), 404
    
    logs = get_collection(Collections.VISITOR_LOGS)
    
    # Check if already checked in (auto checkout)
    recent_log = logs.find_one({
        'visitor_id': visitor_id,
        'status': 'checked_in',
        'check_out_time': None
    }, sort=[('check_in_time', -1)])
    
    if recent_log:
        # Auto check-out
        logs.update_one(
            {'_id': recent_log['_id']},
            {'$set': {
                'status': 'checked_out',
                'check_out_time': datetime.utcnow()
            }}
        )
        return jsonify({'success': True, 'message': 'Checked out', 'action': 'checkout'})
    
    # New check-in
    purpose = user_doc.get('purpose', 'General visit')
    log = VisitorLogModel.create_log(visitor_id, purpose)
    result = logs.insert_one(log)
    
    return jsonify({
        'success': True,
        'message': 'Checked in successfully',
        'log_id': str(result.inserted_id),
        'purpose': purpose
    })

