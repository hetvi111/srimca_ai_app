"""
Faculty management routes for SRIMCA AI Backend
Handles CRUD operations for faculty data in the normalized Faculty collection

NORMALIZED: Faculty data is stored in a separate collection
linked to Users collection via user_id
"""

from flask import Blueprint, request, jsonify
from bson import ObjectId
from datetime import datetime

from database import get_collection, Collections
from models import FacultyModel, UserModel
from auth import verify_jwt_token

# Create faculty blueprint
faculty_bp = Blueprint('faculty', __name__, url_prefix='/api/faculty')


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


@faculty_bp.route('/', methods=['GET'])
@require_auth
def get_faculty():
    """
    Get all faculty members (admin only)
    Requires authentication
    Query params: limit, offset, department, designation
    """
    try:
        # Check if user is admin
        if request.user.get('role') != 'admin':
            return jsonify({'error': 'Unauthorized - Admin only'}), 403
        
        # Parse query parameters
        limit = int(request.args.get('limit', 50))
        offset = int(request.args.get('offset', 0))
        department = request.args.get('department')
        designation = request.args.get('designation')
        
        # Build query
        query = {}
        
        if department:
            query['department'] = department
        
        if designation:
            query['designation'] = designation
        
        # Get faculty from database
        faculty_collection = get_collection(Collections.FACULTIES)
        faculty_list = list(faculty_collection.find(query)
                          .sort('created_at', -1)
                          .skip(offset)
                          .limit(limit))
        
        # Get user details for each faculty
        users_collection = get_collection(Collections.USERS)
        
        result = []
        for fac in faculty_list:
            faculty_dict = FacultyModel.to_dict(fac)
            
            # Get user info
            user = users_collection.find_one({'_id': ObjectId(fac.get('user_id'))})
            if user:
                faculty_dict['user'] = UserModel.to_dict(user)
            
            result.append(faculty_dict)
        
        return jsonify({
            'faculty': result,
            'count': len(result),
            'total': faculty_collection.count_documents(query)
        }), 200
    
    except Exception as e:
        print(f"Get faculty error: {e}")
        return jsonify({'error': 'Failed to get faculty'}), 500


@faculty_bp.route('/<faculty_id>', methods=['GET'])
@require_auth
def get_faculty_member(faculty_id):
    """
    Get a single faculty member by ID
    """
    try:
        faculty_collection = get_collection(Collections.FACULTIES)
        faculty = faculty_collection.find_one({'_id': ObjectId(faculty_id)})
        
        if not faculty:
            return jsonify({'error': 'Faculty not found'}), 404
        
        faculty_dict = FacultyModel.to_dict(faculty)
        
        # Get user info
        users_collection = get_collection(Collections.USERS)
        user = users_collection.find_one({'_id': ObjectId(faculty.get('user_id'))})
        if user:
            faculty_dict['user'] = UserModel.to_dict(user)
        
        return jsonify({'faculty': faculty_dict}), 200
    
    except Exception as e:
        print(f"Get faculty error: {e}")
        return jsonify({'error': 'Failed to get faculty'}), 500


@faculty_bp.route('/user/<user_id>', methods=['GET'])
@require_auth
def get_faculty_by_user_id(user_id):
    """
    Get faculty by user_id
    """
    try:
        faculty_collection = get_collection(Collections.FACULTIES)
        faculty = faculty_collection.find_one({'user_id': user_id})
        
        if not faculty:
            return jsonify({'error': 'Faculty record not found'}), 404
        
        faculty_dict = FacultyModel.to_dict(faculty)
        
        # Get user info
        users_collection = get_collection(Collections.USERS)
        user = users_collection.find_one({'_id': ObjectId(user_id)})
        if user:
            faculty_dict['user'] = UserModel.to_dict(user)
        
        return jsonify({'faculty': faculty_dict}), 200
    
    except Exception as e:
        print(f"Get faculty by user_id error: {e}")
        return jsonify({'error': 'Failed to get faculty'}), 500


@faculty_bp.route('/', methods=['POST'])
@require_auth
def create_faculty():
    """
    Create a new faculty record (admin only)
    Requires authentication
    """
    try:
        # Check if user is admin
        if request.user.get('role') != 'admin':
            return jsonify({'error': 'Only admins can create faculty records'}), 403
        
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['user_id', 'department', 'designation']
        for field in required_fields:
            if not data.get(field):
                return jsonify({'error': f'{field} is required'}), 400
        
        # Check if user exists
        users_collection = get_collection(Collections.USERS)
        user = users_collection.find_one({'_id': ObjectId(data['user_id'])})
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Check if faculty already exists
        faculty_collection = get_collection(Collections.FACULTIES)
        existing_faculty = faculty_collection.find_one({'user_id': data['user_id']})
        if existing_faculty:
            return jsonify({'error': 'Faculty record already exists for this user'}), 409
        
        # Create faculty document
        faculty_doc = FacultyModel.create_faculty(
            user_id=data['user_id'],
            department=data['department'],
            designation=data['designation']
        )
        
        # Insert into database
        result = faculty_collection.insert_one(faculty_doc)
        
        faculty_doc['_id'] = result.inserted_id
        
        return jsonify({
            'message': 'Faculty record created successfully',
            'faculty': FacultyModel.to_dict(faculty_doc)
        }), 201
    
    except Exception as e:
        print(f"Create faculty error: {e}")
        return jsonify({'error': 'Failed to create faculty record'}), 500


@faculty_bp.route('/<faculty_id>', methods=['PUT'])
@require_auth
def update_faculty(faculty_id):
    """
    Update a faculty record
    Requires authentication (admin only)
    """
    try:
        # Check if user is admin
        if request.user.get('role') != 'admin':
            return jsonify({'error': 'Only admins can update faculty records'}), 403
        
        data = request.get_json()
        
        # Build update document
        update_data = {}
        
        if data.get('department'):
            update_data['department'] = data['department']
        
        if data.get('designation'):
            update_data['designation'] = data['designation']
        
        if not update_data:
            return jsonify({'error': 'No fields to update'}), 400
        
        update_data['updated_at'] = datetime.utcnow()
        
        # Update in database
        faculty_collection = get_collection(Collections.FACULTIES)
        result = faculty_collection.update_one(
            {'_id': ObjectId(faculty_id)},
            {'$set': update_data}
        )
        
        if result.matched_count == 0:
            return jsonify({'error': 'Faculty not found'}), 404
        
        # Get updated faculty
        faculty = faculty_collection.find_one({'_id': ObjectId(faculty_id)})
        
        return jsonify({
            'message': 'Faculty updated successfully',
            'faculty': FacultyModel.to_dict(faculty)
        }), 200
    
    except Exception as e:
        print(f"Update faculty error: {e}")
        return jsonify({'error': 'Failed to update faculty'}), 500


@faculty_bp.route('/<faculty_id>', methods=['DELETE'])
@require_auth
def delete_faculty(faculty_id):
    """
    Delete a faculty record (admin only)
    Requires authentication
    """
    try:
        # Check if user is admin
        if request.user.get('role') != 'admin':
            return jsonify({'error': 'Only admins can delete faculty records'}), 403
        
        faculty_collection = get_collection(Collections.FACULTIES)
        
        # Delete faculty
        result = faculty_collection.delete_one({'_id': ObjectId(faculty_id)})
        
        if result.deleted_count == 0:
            return jsonify({'error': 'Faculty not found'}), 404
        
        return jsonify({'message': 'Faculty deleted successfully'}), 200
    
    except Exception as e:
        print(f"Delete faculty error: {e}")
        return jsonify({'error': 'Failed to delete faculty'}), 500

