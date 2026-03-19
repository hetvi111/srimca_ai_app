from flask import Blueprint, request, jsonify
from bson import ObjectId
from datetime import datetime, timedelta
from srimca.app import ask
from database import get_collection, Collections
from models import AIQueryModel

ai_bp = Blueprint('ai', __name__, url_prefix='/api/ai')

@ai_bp.route('/chat', methods=['POST'])
def chat():
    """AI Chat endpoint for frontend"""
    data = request.get_json()
    question = data.get('question', '').strip()
    user_id = data.get('user_id', '').strip()
    
    if not question:
        return jsonify({
            'status': 'error', 
            'message': 'Question required'
        }), 400
    
    try:
        answer = ask(question)
        # Save query for monitoring if a user id is provided.
        if user_id:
            ai_queries = get_collection(Collections.AI_QUERIES)
            query_doc = AIQueryModel.create_query(
                user_id=user_id,
                query=question,
                response=answer
            )
            ai_queries.insert_one(query_doc)
        return jsonify({
            'status': 'success', 
            'answer': answer
        })
    except Exception as e:
        return jsonify({
            'status': 'error', 
            'message': f'AI service error: {str(e)}'
        }), 500


@ai_bp.route('/queries', methods=['GET'])
def get_queries():
    """Get AI queries for monitoring dashboard"""
    try:
        limit = int(request.args.get('limit', 100))
        period = request.args.get('period', 'all').lower()

        query_filter = {}
        now = datetime.utcnow()
        if period == 'today':
            start = datetime(now.year, now.month, now.day)
            query_filter['created_at'] = {'$gte': start}
        elif period == 'week':
            query_filter['created_at'] = {'$gte': now - timedelta(days=7)}

        ai_queries_collection = get_collection(Collections.AI_QUERIES)
        users_collection = get_collection(Collections.USERS)

        docs = list(
            ai_queries_collection.find(query_filter)
            .sort('created_at', -1)
            .limit(limit)
        )

        queries = []
        for doc in docs:
            user_name = 'Unknown User'
            user_doc = None
            user_id = doc.get('user_id')

            if user_id:
                try:
                    user_doc = users_collection.find_one({'_id': ObjectId(user_id)})
                except Exception:
                    user_doc = users_collection.find_one({'_id': user_id})

            if user_doc:
                user_name = user_doc.get('name', 'Unknown User')

            queries.append({
                '_id': str(doc.get('_id', '')),
                'student': user_name,
                'question': doc.get('query', ''),
                'answer': doc.get('response', ''),
                'timestamp': doc.get('created_at').isoformat() if doc.get('created_at') else None
            })

        total_queries = ai_queries_collection.count_documents({})
        today_start = datetime(now.year, now.month, now.day)
        today_queries = ai_queries_collection.count_documents({'created_at': {'$gte': today_start}})

        return jsonify({
            'queries': queries,
            'stats': {
                'total_queries': total_queries,
                'today_queries': today_queries,
                'avg_response': '<2s'
            }
        }), 200
    except Exception as e:
        return jsonify({'error': f'Failed to fetch AI queries: {str(e)}'}), 500
