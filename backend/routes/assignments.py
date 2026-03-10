"""
Assignment management routes for SRIMCA AI Backend
Handles CRUD operations for coursework assignments
"""

from flask import Blueprint, request, jsonify
from bson import ObjectId
from datetime import datetime

from database import get_collection, Collections
from models import AssignmentModel
from auth import verify_jwt_token
from notification_helper import create_notification

# Create assignments blueprint
assignments_bp = Blueprint('assignments', __name__, url_prefix='/api/assignments')


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


@assignments_bp.route('/', methods=['GET'], endpoint='get_assignments')
def get_assignments():
    """
    Get all assignments
    Query params: limit, offset, subject, faculty_id
    """
    try:
        # Parse query parameters
        limit = int(request.args.get('limit', 50))
        offset = int(request.args.get('offset', 0))
        subject = request.args.get('subject')
        faculty_id = request.args.get('faculty_id')
        
        # Build query
        query = {'is_active': True}
        
        if subject:
            query['subject'] = subject
        
        if faculty_id:
            query['faculty_id'] = faculty_id
        
        # Get assignments from database
        assignments_collection = get_collection(Collections.ASSIGNMENTS)
        assignments = list(assignments_collection.find(query)
                          .sort('due_date', 1)
                          .skip(offset)
                          .limit(limit))
        
        # Convert to dict
        result = [AssignmentModel.to_dict(a) for a in assignments]
        
        return jsonify({
            'assignments': result,
            'count': len(result),
            'total': assignments_collection.count_documents(query)
        }), 200
    
    except Exception as e:
        print(f"Get assignments error: {e}")
        return jsonify({'error': 'Failed to get assignments'}), 500


@assignments_bp.route('/<assignment_id>', methods=['GET'], endpoint='get_assignment')
def get_assignment(assignment_id):
    """
    Get a single assignment by ID
    """
    try:
        assignments_collection = get_collection(Collections.ASSIGNMENTS)
        assignment = assignments_collection.find_one({'_id': ObjectId(assignment_id), 'is_active': True})
        
        if not assignment:
            return jsonify({'error': 'Assignment not found'}), 404
        
        return jsonify({'assignment': AssignmentModel.to_dict(assignment)}), 200
    
    except Exception as e:
        print(f"Get assignment error: {e}")
        return jsonify({'error': 'Failed to get assignment'}), 500


@assignments_bp.route('/', methods=['POST'], endpoint='create_assignment')
@require_auth
def create_assignment():
    """
    Create a new assignment
    Requires authentication (faculty/admin only)
    """
    try:
        # Check if user is faculty or admin
        role = request.user.get('role', '')
        if role not in ['faculty', 'admin']:
            return jsonify({'error': 'Only faculty and admin can create assignments'}), 403
        
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['title', 'description', 'due_date', 'subject']
        for field in required_fields:
            if not data.get(field):
                return jsonify({'error': f'{field} is required'}), 400
        
        # Create assignment document
        assignment_doc = AssignmentModel.create_assignment(
            title=data['title'],
            description=data['description'],
            due_date=data['due_date'],
            faculty_id=request.user.get('user_id'),
            subject=data['subject'],
            max_marks=data.get('max_marks', 100)
        )
        
        # Insert into database
        assignments_collection = get_collection(Collections.ASSIGNMENTS)
        result = assignments_collection.insert_one(assignment_doc)
        
        assignment_doc['_id'] = result.inserted_id
        
        # Create notification for new assignment
        create_notification(
            title='New Assignment Posted',
            message=f'A new assignment "{data.get("title", "")}" has been posted',
            notification_type='upload'
        )
        
        return jsonify({
            'message': 'Assignment created successfully',
            'assignment': AssignmentModel.to_dict(assignment_doc)
        }), 201
    
    except Exception as e:
        print(f"Create assignment error: {e}")
        return jsonify({'error': 'Failed to create assignment'}), 500


@assignments_bp.route('/<assignment_id>', methods=['PUT'], endpoint='update_assignment')
@require_auth
def update_assignment(assignment_id):
    """
    Update an assignment
    Requires authentication (faculty/admin only)
    """
    try:
        # Check if user is faculty or admin
        role = request.user.get('role', '')
        if role not in ['faculty', 'admin']:
            return jsonify({'error': 'Only faculty and admin can update assignments'}), 403
        
        data = request.get_json()
        
        # Build update document
        update_data = {
            'updated_at': datetime.utcnow()
        }
        
        allowed_fields = ['title', 'description', 'due_date', 'subject', 'max_marks']
        for field in allowed_fields:
            if data.get(field):
                update_data[field] = data[field]
        
        # Update in database
        assignments_collection = get_collection(Collections.ASSIGNMENTS)
        result = assignments_collection.update_one(
            {'_id': ObjectId(assignment_id)},
            {'$set': update_data}
        )
        
        if result.matched_count == 0:
            return jsonify({'error': 'Assignment not found'}), 404
        
        # Get updated assignment
        assignment = assignments_collection.find_one({'_id': ObjectId(assignment_id)})
        
        return jsonify({
            'message': 'Assignment updated successfully',
            'assignment': AssignmentModel.to_dict(assignment)
        }), 200
    
    except Exception as e:
        print(f"Update assignment error: {e}")
        return jsonify({'error': 'Failed to update assignment'}), 500


@assignments_bp.route('/<assignment_id>', methods=['DELETE'], endpoint='delete_assignment')
@require_auth
def delete_assignment(assignment_id):
    """
    Delete (deactivate) an assignment
    Requires authentication (faculty/admin only)
    """
    try:
        # Check if user is faculty or admin
        role = request.user.get('role', '')
        if role not in ['faculty', 'admin']:
            return jsonify({'error': 'Only faculty and admin can delete assignments'}), 403
        
        assignments_collection = get_collection(Collections.ASSIGNMENTS)
        
        # Soft delete - set is_active to False
        result = assignments_collection.update_one(
            {'_id': ObjectId(assignment_id)},
            {'$set': {'is_active': False, 'deleted_at': datetime.utcnow()}}
        )
        
        if result.matched_count == 0:
            return jsonify({'error': 'Assignment not found'}), 404
        
        return jsonify({'message': 'Assignment deleted successfully'}), 200
    
    except Exception as e:
        print(f"Delete assignment error: {e}")
        return jsonify({'error': 'Failed to delete assignment'}), 500


@assignments_bp.route('/<assignment_id>/submit', methods=['POST'], endpoint='submit_assignment')
@require_auth
def submit_assignment(assignment_id):
    """
    Submit an assignment (student submission)
    Requires authentication
    """
    try:
        data = request.get_json()
        
        if not data.get('submission_text'):
            return jsonify({'error': 'Submission text is required'}), 400
        
        # Get assignment
        assignments_collection = get_collection(Collections.ASSIGNMENTS)
        assignment = assignments_collection.find_one({'_id': ObjectId(assignment_id), 'is_active': True})
        
        if not assignment:
            return jsonify({'error': 'Assignment not found'}), 404
        
        # Create submission
        submission = {
            'student_id': request.user.get('user_id'),
            'student_name': request.user.get('name'),
            'submission_text': data['submission_text'],
            'submitted_at': datetime.utcnow(),
            'marks': None,
            'feedback': None
        }
        
        # Add submission to assignment
        assignments_collection.update_one(
            {'_id': ObjectId(assignment_id)},
            {'$push': {'submissions': submission}}
        )
        
        return jsonify({
            'message': 'Assignment submitted successfully',
            'submission': submission
        }), 201
    
    except Exception as e:
        print(f"Submit assignment error: {e}")
        return jsonify({'error': 'Failed to submit assignment'}), 500
