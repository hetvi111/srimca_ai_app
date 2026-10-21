import re
from flask import Blueprint, request, jsonify
from bson import ObjectId
from datetime import datetime, timedelta
from srimca.app import ask
from database import get_collection, Collections
from models import AIQueryModel

from srimca.recommendations import generate_recommendations

ai_bp = Blueprint('ai', __name__, url_prefix='/api/ai')


from campus_navigation import handle_campus_location_query, get_all_locations_safe


def process_ai_request(save_query=True):
    data = request.get_json() or {}

    question = data.get('question', '').strip()
    user_id = data.get('user_id', '').strip()
    user_role = data.get('role', data.get('user_role', 'student')).strip()
    user_course = data.get('course', '').strip()
    user_semester = data.get('semester', '').strip()

    if not question:
        return jsonify({
            'status': 'error',
            'message': 'Question required'
        }), 400

    try:
        # Step 1: Detect and handle campus navigation / location intent
        is_location_query, location_response = handle_campus_location_query(question)
        if is_location_query and location_response:
            if save_query and user_id:
                try:
                    ai_queries = get_collection(Collections.AI_QUERIES)
                    query_doc = AIQueryModel.create_query(
                        user_id=user_id,
                        query=question,
                        response=location_response.get('answer', '')
                    )
                    ai_queries.insert_one(query_doc)
                except Exception as save_err:
                    print(f"[AI] Notice saving location query to MongoDB: {save_err}")

            return jsonify(location_response)

        # Step 2: Regular AI knowledge base & RAG question answering
        answer = ask(question)

        if not answer:
            answer = "I couldn't generate a response."

        rec = generate_recommendations(
            question=question,
            answer=answer,
            user_role=user_role,
            course=user_course,
            semester=user_semester
        )

        if save_query and user_id:
            try:
                ai_queries = get_collection(Collections.AI_QUERIES)

                query_doc = AIQueryModel.create_query(
                    user_id=user_id,
                    query=question,
                    response=answer
                )

                ai_queries.insert_one(query_doc)
            except Exception as save_err:
                print(f"[AI] Notice saving query to MongoDB: {save_err}")

        # Check if the query is unanswered / fallback so admin can review and create an approved answer
        try:
            is_unresolved = (
                "don't have information on that" in answer.lower()
                or "ક્ષમા કરશો" in answer
                or "क्षमा करें" in answer
                or "couldn't generate a response" in answer.lower()
            )
            if is_unresolved:
                unresolved_col = get_collection(Collections.UNRESOLVED_QUERIES)
                existing = unresolved_col.find_one({
                    'question': {'$regex': f"^{re.escape(question.strip())}$", '$options': 'i'},
                    'status': 'pending'
                })
                if not existing:
                    unresolved_col.insert_one({
                        'question': question.strip(),
                        'user_id': user_id or '',
                        'user_role': user_role or 'student',
                        'status': 'pending',
                        'approved_answer': '',
                        'resolved_by': '',
                        'created_at': datetime.utcnow(),
                        'resolved_at': None
                    })
        except Exception as unres_err:
            print(f"[AI] Notice logging unresolved query: {unres_err}")

        return jsonify({
            'status': 'success',
            'success': True,
            'type': 'text',
            'answer': answer,
            'reply': answer,
            'location': None,
            'follow_up_questions': rec['follow_up_questions'],
            'suggestions': rec['follow_up_questions'],
            'personalized_guidance': rec['personalized_guidance']
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


# Campus locations directory endpoint
@ai_bp.route('/locations', methods=['GET'])
def get_locations():
    """Return all campus locations for reference and testing"""
    locations = get_all_locations_safe()
    return jsonify({
        'status': 'success',
        'success': True,
        'count': len(locations),
        'locations': locations
    })

