"""
FAQ management routes for SRIMCA AI Backend
Handles CRUD operations for frequently asked questions
"""

from flask import Blueprint, request, jsonify
from bson import ObjectId
from datetime import datetime

from database import get_collection, Collections
from models import FAQModel
from auth import verify_jwt_token

# Create FAQs blueprint
faqs_bp = Blueprint('faqs', __name__, url_prefix='/api/faqs')


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


@faqs_bp.route('/', methods=['GET'])
def get_faqs():
    """
    Get all FAQs
    Query params: limit, offset
    """
    try:
        # Parse query parameters
        limit = int(request.args.get('limit', 50))
        offset = int(request.args.get('offset', 0))
        
        # Build query
        query = {'is_active': True}
        
        # Get FAQs from database
        faqs_collection = get_collection(Collections.FAQS)
        faqs = list(faqs_collection.find(query)
                    .sort('created_at', -1)
                    .skip(offset)
                    .limit(limit))
        
        # Convert to dict
        result = [FAQModel.to_dict(f) for f in faqs]
        
        return jsonify({
            'faqs': result,
            'count': len(result),
            'total': faqs_collection.count_documents(query)
        }), 200
    
    except Exception as e:
        print(f"Get FAQs error: {e}")
        return jsonify({'error': 'Failed to get FAQs'}), 500


@faqs_bp.route('/<faq_id>', methods=['GET'])
def get_faq(faq_id):
    """
    Get a single FAQ by ID
    """
    try:
        faqs_collection = get_collection(Collections.FAQS)
        faq = faqs_collection.find_one({'_id': ObjectId(faq_id), 'is_active': True})
        
        if not faq:
            return jsonify({'error': 'FAQ not found'}), 404
        
        # Increment views
        faqs_collection.update_one({'_id': ObjectId(faq_id)}, {'$inc': {'views': 1}})
        
        return jsonify({'faq': FAQModel.to_dict(faq)}), 200
    
    except Exception as e:
        print(f"Get FAQ error: {e}")
        return jsonify({'error': 'Failed to get FAQ'}), 500


@faqs_bp.route('/', methods=['POST'])
@require_auth
def create_faq():
    """
    Create a new FAQ
    Requires authentication (faculty/admin only)
    """
    try:
        # Check if user is faculty or admin
        role = request.user.get('role', '')
        if role not in ['faculty', 'admin']:
            return jsonify({'error': 'Only faculty and admin can create FAQs'}), 403
        
        data = request.get_json()
        
        # Validate required fields
        if not data.get('question'):
            return jsonify({'error': 'Question is required'}), 400
        
        # Create FAQ document
        faq_doc = FAQModel.create_faq(
            question=data['question'],
            answer=data.get('answer', ''),
            created_by=request.user.get('user_id')
        )
        
        # Insert into database
        faqs_collection = get_collection(Collections.FAQS)
        result = faqs_collection.insert_one(faq_doc)
        
        faq_doc['_id'] = result.inserted_id
        
        return jsonify({
            'message': 'FAQ created successfully',
            'faq': FAQModel.to_dict(faq_doc)
        }), 201
    
    except Exception as e:
        print(f"Create FAQ error: {e}")
        return jsonify({'error': 'Failed to create FAQ'}), 500


@faqs_bp.route('/<faq_id>', methods=['PUT'])
@require_auth
def update_faq(faq_id):
    """
    Update an FAQ
    Requires authentication (faculty/admin only)
    """
    try:
        # Check if user is faculty or admin
        role = request.user.get('role', '')
        if role not in ['faculty', 'admin']:
            return jsonify({'error': 'Only faculty and admin can update FAQs'}), 403
        
        data = request.get_json()
        
        # Build update document
        update_data = {
            'updated_at': datetime.utcnow()
        }
        
        if data.get('question'):
            update_data['question'] = data['question']
        
        if data.get('answer'):
            update_data['answer'] = data['answer']
        
        # Update in database
        faqs_collection = get_collection(Collections.FAQS)
        result = faqs_collection.update_one(
            {'_id': ObjectId(faq_id)},
            {'$set': update_data}
        )
        
        if result.matched_count == 0:
            return jsonify({'error': 'FAQ not found'}), 404
        
        # Get updated FAQ
        faq = faqs_collection.find_one({'_id': ObjectId(faq_id)})
        
        return jsonify({
            'message': 'FAQ updated successfully',
            'faq': FAQModel.to_dict(faq)
        }), 200
    
    except Exception as e:
        print(f"Update FAQ error: {e}")
        return jsonify({'error': 'Failed to update FAQ'}), 500


@faqs_bp.route('/<faq_id>', methods=['DELETE'])
@require_auth
def delete_faq(faq_id):
    """
    Delete (deactivate) an FAQ
    Requires authentication (faculty/admin only)
    """
    try:
        # Check if user is faculty or admin
        role = request.user.get('role', '')
        if role not in ['faculty', 'admin']:
            return jsonify({'error': 'Only faculty and admin can delete FAQs'}), 403
        
        faqs_collection = get_collection(Collections.FAQS)
        
        # Soft delete - set is_active to False
        result = faqs_collection.update_one(
            {'_id': ObjectId(faq_id)},
            {'$set': {'is_active': False, 'deleted_at': datetime.utcnow()}}
        )
        
        if result.matched_count == 0:
            return jsonify({'error': 'FAQ not found'}), 404
        
        return jsonify({'message': 'FAQ deleted successfully'}), 200
    
    except Exception as e:
        print(f"Delete FAQ error: {e}")
        return jsonify({'error': 'Failed to delete FAQ'}), 500
