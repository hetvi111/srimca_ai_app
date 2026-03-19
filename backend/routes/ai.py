from flask import Blueprint, request, jsonify

from backend.srimca.app import ask

ai_bp = Blueprint('ai', __name__, url_prefix='/api/ai')

@ai_bp.route('/chat', methods=['POST'])
def chat():
    """AI Chat endpoint for frontend"""
    data = request.get_json()
    question = data.get('question', '').strip()
    
    if not question:
        return jsonify({
            'status': 'error', 
            'message': 'Question required'
        }), 400
    
    try:
        answer = ask(question)
        return jsonify({
            'status': 'success', 
            'answer': answer
        })
    except Exception as e:
        return jsonify({
            'status': 'error', 
            'message': f'AI service error: {str(e)}'
        }), 500
