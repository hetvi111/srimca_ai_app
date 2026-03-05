"""
Student management routes for SRIMCA AI Backend
Handles CRUD operations for student data in the normalized Students collection

NORMALIZED: Student data is stored in a separate collection
linked to Users collection via user_id
"""

from flask import Blueprint, request, jsonify
from bson import ObjectId

from database import get_collection, Collections
from models import StudentModel, UserModel
from auth import verify_jwt_token

# Create students blueprint
students_bp = Blueprint('students', __name__, url_prefix='/api/students')


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


@students_bp.route('/', methods=['GET'])
@require_auth
def get_students():
    """
    Get all students (admin/faculty only)
    Requires authentication
    Query params: limit, offset, semester, department
    """
    try:
        # Check if user is admin or faculty
        role = request.user.get('role', '')
        if role not in ['admin', 'faculty']:
            return jsonify({'error': 'Unauthorized - Admin/Faculty only'}), 403
        
        # Parse query parameters
        limit = int(request.args.get('limit', 50))
        offset = int(request.args.get('offset', 0))
        semester = request.args.get('semester')
        department = request.args.get('department')
        
        # Build query
        query = {}
        
        if semester:
            query['semester'] = semester
        
        if department:
            query['department'] = department
        
        # Get students from database
        students_collection = get_collection(Collections.STUDENTS)
        students = list(students_collection.find(query)
                      .sort('created_at', -1)
                      .skip(offset)
                      .limit(limit))
        
        # Get user details for each student
        users_collection = get_collection(Collections.USERS)
        
        result = []
        for student in students:
            student_dict = StudentModel.to_dict(student)
            
            # Get user info
            user = users_collection.find_one({'_id': ObjectId(student.get('user_id'))})
            if user:
                student_dict['user'] = UserModel.to_dict(user)
            
            result.append(student_dict)
        
        return jsonify({
            'students': result,
            'count': len(result),
            'total': students_collection.count_documents(query)
        }), 200
    
    except Exception as e:
        print(f"Get students error: {e}")
        return jsonify({'error': 'Failed to get students'}), 500


@students_bp.route('/<student_id>', methods=['GET'])
@require_auth
def get_student(student_id):
    """
    Get a single student by ID
    """
    try:
        students_collection = get_collection(Collections.STUDENTS)
        student = students_collection.find_one({'_id': ObjectId(student_id)})
        
        if not student:
            return jsonify({'error': 'Student not found'}), 404
        
        student_dict = StudentModel.to_dict(student)
        
        # Get user info
        users_collection = get_collection(Collections.USERS)
        user = users_collection.find_one({'_id': ObjectId(student.get('user_id'))})
        if user:
            student_dict['user'] = UserModel.to_dict(user)
        
        return jsonify({'student': student_dict}), 200
    
    except Exception as e:
        print(f"Get student error: {e}")
        return jsonify({'error': 'Failed to get student'}), 500


@students_bp.route('/user/<user_id>', methods=['GET'])
@require_auth
def get_student_by_user_id(user_id):
    """
    Get student by user_id
    """
    try:
        students_collection = get_collection(Collections.STUDENTS)
        student = students_collection.find_one({'user_id': user_id})
        
        if not student:
            return jsonify({'error': 'Student record not found'}), 404
        
        student_dict = StudentModel.to_dict(student)
        
        # Get user info
        users_collection = get_collection(Collections.USERS)
        user = users_collection.find_one({'_id': ObjectId(user_id)})
        if user:
            student_dict['user'] = UserModel.to_dict(user)
        
        return jsonify({'student': student_dict}), 200
    
    except Exception as e:
        print(f"Get student by user_id error: {e}")
        return jsonify({'error': 'Failed to get student'}), 500


@students_bp.route('/', methods=['POST'])
@require_auth
def create_student():
    """
    Create a new student record (admin only)
    Requires authentication
    """
    try:
        # Check if user is admin
        if request.user.get('role') != 'admin':
            return jsonify({'error': 'Only admins can create student records'}), 403
        
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['user_id', 'semester', 'department', 'enrollment_number']
        for field in required_fields:
            if not data.get(field):
                return jsonify({'error': f'{field} is required'}), 400
        
        # Check if user exists
        users_collection = get_collection(Collections.USERS)
        user = users_collection.find_one({'_id': ObjectId(data['user_id'])})
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Check if student already exists
        students_collection = get_collection(Collections.STUDENTS)
        existing_student = students_collection.find_one({'user_id': data['user_id']})
        if existing_student:
            return jsonify({'error': 'Student record already exists for this user'}), 409
        
        # Create student document
        student_doc = StudentModel.create_student(
            user_id=data['user_id'],
            semester=data['semester'],
            department=data['department'],
            enrollment_number=data['enrollment_number']
        )
        
        # Add optional fields
        if data.get('dob'):
            student_doc['dob'] = data['dob']
        
        # Insert into database
        result = students_collection.insert_one(student_doc)
        
        student_doc['_id'] = result.inserted_id
        
        return jsonify({
            'message': 'Student record created successfully',
            'student': StudentModel.to_dict(student_doc)
        }), 201
    
    except Exception as e:
        print(f"Create student error: {e}")
        return jsonify({'error': 'Failed to create student record'}), 500


@students_bp.route('/<student_id>', methods=['PUT'])
@require_auth
def update_student(student_id):
    """
    Update a student record
    Requires authentication (admin/faculty)
    """
    try:
        # Check if user is admin or faculty
        role = request.user.get('role', '')
        if role not in ['admin', 'faculty']:
            return jsonify({'error': 'Unauthorized - Admin/Faculty only'}), 403
        
        data = request.get_json()
        
        # Build update document
        update_data = {}
        
        if data.get('semester'):
            update_data['semester'] = data['semester']
        
        if data.get('department'):
            update_data['department'] = data['department']
        
        if data.get('enrollment_number'):
            update_data['enrollment_number'] = data['enrollment_number']
        
        if data.get('dob'):
            update_data['dob'] = data['dob']
        
        if not update_data:
            return jsonify({'error': 'No fields to update'}), 400
        
        update_data['updated_at'] = datetime.utcnow()
        
        # Update in database
        students_collection = get_collection(Collections.STUDENTS)
        result = students_collection.update_one(
            {'_id': ObjectId(student_id)},
            {'$set': update_data}
        )
        
        if result.matched_count == 0:
            return jsonify({'error': 'Student not found'}), 404
        
        # Get updated student
        student = students_collection.find_one({'_id': ObjectId(student_id)})
        
        return jsonify({
            'message': 'Student updated successfully',
            'student': StudentModel.to_dict(student)
        }), 200
    
    except Exception as e:
        print(f"Update student error: {e}")
        return jsonify({'error': 'Failed to update student'}), 500


@students_bp.route('/<student_id>', methods=['DELETE'])
@require_auth
def delete_student(student_id):
    """
    Delete a student record (admin only)
    Requires authentication
    """
    try:
        # Check if user is admin
        if request.user.get('role') != 'admin':
            return jsonify({'error': 'Only admins can delete student records'}), 403
        
        students_collection = get_collection(Collections.STUDENTS)
        
        # Delete student
        result = students_collection.delete_one({'_id': ObjectId(student_id)})
        
        if result.deleted_count == 0:
            return jsonify({'error': 'Student not found'}), 404
        
        return jsonify({'message': 'Student deleted successfully'}), 200
    
    except Exception as e:
        print(f"Delete student error: {e}")
        return jsonify({'error': 'Failed to delete student'}), 500


# Import datetime at the top level
from datetime import datetime

