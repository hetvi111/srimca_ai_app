"""
Knowledge management routes for SRIMCA AI Backend
Handles CRUD operations for AI knowledge base used by the chatbot

NORMALIZED: Knowledge data is stored in a separate collection
for the AI RAG (Retrieval-Augmented Generation) system
"""

from flask import Blueprint, request, jsonify
from bson import ObjectId
from datetime import datetime

from database import get_collection, Collections
from models import KnowledgeModel
from auth import verify_jwt_token

# Create knowledge blueprint
knowledge_bp = Blueprint('knowledge', __name__, url_prefix='/api/knowledge')


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


@knowledge_bp.route('/', methods=['GET'])
def get_knowledge():
    """
    Get all knowledge entries
    Public endpoint - used by AI chatbot
    Query params: limit, offset, category, is_active
    """
    try:
        # Parse query parameters
        limit = int(request.args.get('limit', 100))
        offset = int(request.args.get('offset', 0))
        category = request.args.get('category')
        
        # Build query - only return active entries for chatbot
        query = {'is_active': True}
        
        if category:
            query['category'] = category
        
        # Get knowledge from database
        knowledge_collection = get_collection(Collections.KNOWLEDGE)
        knowledge_list = list(knowledge_collection.find(query)
                            .sort('usage_count', -1)  # Most used first
                            .skip(offset)
                            .limit(limit))
        
        # Convert to dict
        result = [KnowledgeModel.to_dict(k) for k in knowledge_list]
        
        return jsonify({
            'knowledge': result,
            'count': len(result),
            'total': knowledge_collection.count_documents(query)
        }), 200
    
    except Exception as e:
        print(f"Get knowledge error: {e}")
        return jsonify({'error': 'Failed to get knowledge'}), 500


@knowledge_bp.route('/search', methods=['GET'])
def search_knowledge():
    """
    Search knowledge entries by question or answer
    Public endpoint - used by AI chatbot
    Query params: q (search query)
    """
    try:
        search_query = request.args.get('q', '')
        
        if not search_query:
            return jsonify({'error': 'Search query is required'}), 400
        
        # Build regex search
        query = {
            'is_active': True,
            '$or': [
                {'question': {'$regex': search_query, '$options': 'i'}},
                {'answer': {'$regex': search_query, '$options': 'i'}}
            ]
        }
        
        # Get knowledge from database
        knowledge_collection = get_collection(Collections.KNOWLEDGE)
        knowledge_list = list(knowledge_collection.find(query).limit(10))
        
        # Convert to dict
        result = [KnowledgeModel.to_dict(k) for k in knowledge_list]
        
        return jsonify({
            'results': result,
            'count': len(result),
            'query': search_query
        }), 200
    
    except Exception as e:
        print(f"Search knowledge error: {e}")
        return jsonify({'error': 'Failed to search knowledge'}), 500


@knowledge_bp.route('/<knowledge_id>', methods=['GET'])
def get_knowledge_entry(knowledge_id):
    """
    Get a single knowledge entry by ID
    """
    try:
        knowledge_collection = get_collection(Collections.KNOWLEDGE)
        knowledge = knowledge_collection.find_one({'_id': ObjectId(knowledge_id)})
        
        if not knowledge:
            return jsonify({'error': 'Knowledge entry not found'}), 404
        
        # Increment usage count
        knowledge_collection.update_one(
            {'_id': ObjectId(knowledge_id)},
            {'$inc': {'usage_count': 1}}
        )
        
        return jsonify({'knowledge': KnowledgeModel.to_dict(knowledge)}), 200
    
    except Exception as e:
        print(f"Get knowledge error: {e}")
        return jsonify({'error': 'Failed to get knowledge'}), 500


@knowledge_bp.route('/', methods=['POST'])
@require_auth
def create_knowledge():
    """
    Create a new knowledge entry
    Requires authentication (admin only)
    """
    try:
        # Check if user is admin
        if request.user.get('role') != 'admin':
            return jsonify({'error': 'Only admins can add knowledge entries'}), 403
        
        data = request.get_json()
        
        # Validate required fields
        if not data.get('question') or not data.get('answer'):
            return jsonify({'error': 'Question and answer are required'}), 400
        
        # Create knowledge document
        knowledge_doc = KnowledgeModel.create_knowledge(
            question=data['question'],
            answer=data['answer'],
            category=data.get('category', 'general'),
            embedding=data.get('embedding', [])
        )
        
        # Insert into database
        knowledge_collection = get_collection(Collections.KNOWLEDGE)
        result = knowledge_collection.insert_one(knowledge_doc)
        
        knowledge_doc['_id'] = result.inserted_id
        
        return jsonify({
            'message': 'Knowledge entry created successfully',
            'knowledge': KnowledgeModel.to_dict(knowledge_doc)
        }), 201
    
    except Exception as e:
        print(f"Create knowledge error: {e}")
        return jsonify({'error': 'Failed to create knowledge entry'}), 500


@knowledge_bp.route('/bulk', methods=['POST'])
@require_auth
def create_bulk_knowledge():
    """
    Create multiple knowledge entries at once
    Requires authentication (admin only)
    Request body: { "entries": [{ "question": "", "answer": "", "category": "" }, ...] }
    """
    try:
        # Check if user is admin
        if request.user.get('role') != 'admin':
            return jsonify({'error': 'Only admins can add knowledge entries'}), 403
        
        data = request.get_json()
        
        if not data.get('entries'):
            return jsonify({'error': 'Entries array is required'}), 400
        
        entries = data.get('entries', [])
        
        # Create knowledge documents
        knowledge_docs = []
        for entry in entries:
            if entry.get('question') and entry.get('answer'):
                doc = KnowledgeModel.create_knowledge(
                    question=entry['question'],
                    answer=entry['answer'],
                    category=entry.get('category', 'general'),
                    embedding=entry.get('embedding', [])
                )
                knowledge_docs.append(doc)
        
        if not knowledge_docs:
            return jsonify({'error': 'No valid entries to insert'}), 400
        
        # Insert into database
        knowledge_collection = get_collection(Collections.KNOWLEDGE)
        result = knowledge_collection.insert_many(knowledge_docs)
        
        return jsonify({
            'message': f'{len(result.inserted_ids)} knowledge entries created successfully',
            'count': len(result.inserted_ids)
        }), 201
    
    except Exception as e:
        print(f"Bulk create knowledge error: {e}")
        return jsonify({'error': 'Failed to create knowledge entries'}), 500


@knowledge_bp.route('/<knowledge_id>', methods=['PUT'])
@require_auth
def update_knowledge(knowledge_id):
    """
    Update a knowledge entry
    Requires authentication (admin only)
    """
    try:
        # Check if user is admin
        if request.user.get('role') != 'admin':
            return jsonify({'error': 'Only admins can update knowledge entries'}), 403
        
        data = request.get_json()
        
        # Build update document
        update_data = {
            'updated_at': datetime.utcnow()
        }
        
        if data.get('question'):
            update_data['question'] = data['question']
        
        if data.get('answer'):
            update_data['answer'] = data['answer']
        
        if data.get('category'):
            update_data['category'] = data['category']
        
        if data.get('embedding'):
            update_data['embedding'] = data['embedding']
        
        if 'is_active' in data:
            update_data['is_active'] = data['is_active']
        
        if len(update_data) == 1:  # Only 'updated_at'
            return jsonify({'error': 'No fields to update'}), 400
        
        # Update in database
        knowledge_collection = get_collection(Collections.KNOWLEDGE)
        result = knowledge_collection.update_one(
            {'_id': ObjectId(knowledge_id)},
            {'$set': update_data}
        )
        
        if result.matched_count == 0:
            return jsonify({'error': 'Knowledge entry not found'}), 404
        
        # Get updated knowledge
        knowledge = knowledge_collection.find_one({'_id': ObjectId(knowledge_id)})
        
        return jsonify({
            'message': 'Knowledge entry updated successfully',
            'knowledge': KnowledgeModel.to_dict(knowledge)
        }), 200
    
    except Exception as e:
        print(f"Update knowledge error: {e}")
        return jsonify({'error': 'Failed to update knowledge entry'}), 500


@knowledge_bp.route('/<knowledge_id>', methods=['DELETE'])
@require_auth
def delete_knowledge(knowledge_id):
    """
    Delete (deactivate) a knowledge entry
    Requires authentication (admin only)
    """
    try:
        # Check if user is admin
        if request.user.get('role') != 'admin':
            return jsonify({'error': 'Only admins can delete knowledge entries'}), 403
        
        knowledge_collection = get_collection(Collections.KNOWLEDGE)
        
        # Soft delete - set is_active to False
        result = knowledge_collection.update_one(
            {'_id': ObjectId(knowledge_id)},
            {'$set': {'is_active': False, 'deleted_at': datetime.utcnow()}}
        )
        
        if result.matched_count == 0:
            return jsonify({'error': 'Knowledge entry not found'}), 404
        
        return jsonify({'message': 'Knowledge entry deleted successfully'}), 200
    
    except Exception as e:
        print(f"Delete knowledge error: {e}")
        return jsonify({'error': 'Failed to delete knowledge entry'}), 500


@knowledge_bp.route('/categories', methods=['GET'])
def get_categories():
    """
    Get all unique categories from knowledge base
    Public endpoint - used for knowledge management UI
    """
    try:
        knowledge_collection = get_collection(Collections.KNOWLEDGE)
        
        # Get distinct categories
        categories = knowledge_collection.distinct('category')
        
        # Get count for each category
        category_counts = []
        for cat in categories:
            count = knowledge_collection.count_documents({'category': cat, 'is_active': True})
            category_counts.append({
                'name': cat,
                'count': count
            })
        
        return jsonify({
            'categories': category_counts,
            'total': len(categories)
        }), 200
    
    except Exception as e:
        print(f"Get categories error: {e}")
        return jsonify({'error': 'Failed to get categories'}), 500

