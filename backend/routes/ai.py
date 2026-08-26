from flask import Blueprint, request, jsonify
from bson import ObjectId
from datetime import datetime, timedelta
from srimca.app import ask
from database import get_collection, Collections
from models import AIQueryModel

ai_bp = Blueprint('ai', __name__, url_prefix='/api/ai')


def process_ai_request(save_query=True):
    data = request.get_json() or {}

    question = data.get('question', '').strip()
    user_id = data.get('user_id', '').strip()

    if not question:
        return jsonify({
            'status': 'error',
            'message': 'Question required'
        }), 400

    try:
        answer = ask(question)

        if not answer:
            answer = "I couldn't generate a response."

        if save_query and user_id:
            ai_queries = get_collection(Collections.AI_QUERIES)

            query_doc = AIQueryModel.create_query(
                user_id=user_id,
                query=question,
                response=answer
            )

            ai_queries.insert_one(query_doc)

        return jsonify({
            'status': 'success',
            'success': True,
            'answer': answer
        })

    except Exception as e:
        return jsonify({
            'status': 'error',
            'success': False,
            'message': str(e)
        }), 500


# Existing endpoint
@ai_bp.route('/chat', methods=['POST'])
def chat():
    return process_ai_request(save_query=True)


# Student endpoint
@ai_bp.route('/ask', methods=['POST'])
def ask_ai():
    return process_ai_request(save_query=True)


# Visitor endpoint
@ai_bp.route('/ask-guest', methods=['POST'])
def ask_guest():
    return process_ai_request(save_query=False)
