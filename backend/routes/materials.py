"""
Study material management routes for SRIMCA AI Backend
Handles CRUD operations for study materials
"""

from flask import Blueprint, request, jsonify
from bson import ObjectId
from datetime import datetime

from database import get_collection, Collections
from models import MaterialModel
from auth import verify_jwt_token
from notification_helper import create_notification

# Create materials blueprint
materials_bp = Blueprint('materials', __name__, url_prefix='/api/materials')


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


@materials_bp.route('/', methods=['GET'])
def get_materials():
    """
    Get all study materials
    Query params: limit, offset, subject, type, faculty_id
    """
    try:
        # Parse query parameters
        limit = int(request.args.get('limit', 50))
        offset = int(request.args.get('offset', 0))
        subject = request.args.get('subject')
        material_type = request.args.get('type')
        faculty_id = request.args.get('faculty_id')
        
        # Build query
        query = {'is_active': True}
        
        if subject:
            query['subject'] = subject
        
        if material_type:
            query['type'] = material_type
        
        if faculty_id:
            query['faculty_id'] = faculty_id
        
        # Get materials from database
        materials_collection = get_collection(Collections.MATERIALS)
        materials = list(materials_collection.find(query)
                       .sort('created_at', -1)
                       .skip(offset)
                       .limit(limit))
        
        # Convert to dict
        result = [MaterialModel.to_dict(m) for m in materials]
        
        return jsonify({
            'materials': result,
            'count': len(result),
            'total': materials_collection.count_documents(query)
        }), 200
    
    except Exception as e:
        print(f"Get materials error: {e}")
        return jsonify({'error': 'Failed to get materials'}), 500


@materials_bp.route('/<material_id>', methods=['GET'])
def get_material(material_id):
    """
    Get a single material by ID
    """
    try:
        materials_collection = get_collection(Collections.MATERIALS)
        material = materials_collection.find_one({'_id': ObjectId(material_id), 'is_active': True})
        
        if not material:
            return jsonify({'error': 'Material not found'}), 404
        
        # Increment downloads
        materials_collection.update_one({'_id': ObjectId(material_id)}, {'$inc': {'downloads': 1}})
        
        return jsonify({'material': MaterialModel.to_dict(material)}), 200
    
    except Exception as e:
        print(f"Get material error: {e}")
        return jsonify({'error': 'Failed to get material'}), 500


@materials_bp.route('/', methods=['POST'])
@require_auth
def create_material():
    """
    Create a new study material
    Requires authentication (faculty/admin only)
    """
    try:
        # Check if user is faculty or admin
        role = request.user.get('role', '')
        if role not in ['faculty', 'admin']:
            return jsonify({'error': 'Only faculty and admin can upload materials'}), 403
        
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['title', 'subject', 'type']
        for field in required_fields:
            if not data.get(field):
                return jsonify({'error': f'{field} is required'}), 400
        
        # Validate material type
        valid_types = ['notes', 'syllabus', 'paper', 'book', 'video', 'other']
        if data['type'] not in valid_types:
            return jsonify({'error': f'Invalid type. Must be one of: {valid_types}'}), 400
        
        # Create material document
        material_doc = MaterialModel.create_material(
            title=data['title'],
            subject=data['subject'],
            type=data['type'],
            faculty_id=request.user.get('user_id'),
            file_url=data.get('file_url', ''),
            description=data.get('description', '')
        )
        
        # Insert into database
        materials_collection = get_collection(Collections.MATERIALS)
        result = materials_collection.insert_one(material_doc)
        
        material_doc['_id'] = result.inserted_id
        
        # Create notification for new material
        create_notification(
            title='New Material Uploaded',
            message=f'A new material "{data.get("title", "")}" ({data.get("subject", "")}) has been uploaded',
            notification_type='upload'
        )
        
        return jsonify({
            'message': 'Material uploaded successfully',
            'material': MaterialModel.to_dict(material_doc)
        }), 201
    
    except Exception as e:
        print(f"Create material error: {e}")
        return jsonify({'error': 'Failed to upload material'}), 500


@materials_bp.route('/<material_id>', methods=['PUT'])
@require_auth
def update_material(material_id):
    """
    Update a study material
    Requires authentication (faculty/admin only)
    """
    try:
        # Check if user is faculty or admin
        role = request.user.get('role', '')
        if role not in ['faculty', 'admin']:
            return jsonify({'error': 'Only faculty and admin can update materials'}), 403
        
        data = request.get_json()
        
        # Build update document
        update_data = {
            'updated_at': datetime.utcnow()
        }
        
        allowed_fields = ['title', 'subject', 'type', 'file_url', 'description']
        for field in allowed_fields:
            if data.get(field):
                update_data[field] = data[field]
        
        # Update in database
        materials_collection = get_collection(Collections.MATERIALS)
        result = materials_collection.update_one(
            {'_id': ObjectId(material_id)},
            {'$set': update_data}
        )
        
        if result.matched_count == 0:
            return jsonify({'error': 'Material not found'}), 404
        
        # Get updated material
        material = materials_collection.find_one({'_id': ObjectId(material_id)})
        
        return jsonify({
            'message': 'Material updated successfully',
            'material': MaterialModel.to_dict(material)
        }), 200
    
    except Exception as e:
        print(f"Update material error: {e}")
        return jsonify({'error': 'Failed to update material'}), 500


@materials_bp.route('/<material_id>', methods=['DELETE'])
@require_auth
def delete_material(material_id):
    """
    Delete (deactivate) a study material
    Requires authentication (faculty/admin only)
    """
    try:
        # Check if user is faculty or admin
        role = request.user.get('role', '')
        if role not in ['faculty', 'admin']:
            return jsonify({'error': 'Only faculty and admin can delete materials'}), 403
        
        materials_collection = get_collection(Collections.MATERIALS)
        
        # Soft delete - set is_active to False
        result = materials_collection.update_one(
            {'_id': ObjectId(material_id)},
            {'$set': {'is_active': False, 'deleted_at': datetime.utcnow()}}
        )
        
        if result.matched_count == 0:
            return jsonify({'error': 'Material not found'}), 404
        
        return jsonify({'message': 'Material deleted successfully'}), 200
    
    except Exception as e:
        print(f"Delete material error: {e}")
        return jsonify({'error': 'Failed to delete material'}), 500
