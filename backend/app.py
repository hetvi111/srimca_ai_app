"""
SRIMCA AI Backend - Main Flask Application
Flask + MongoDB Atlas + Firebase Integration
"""

from flask import Flask, jsonify, request
from flask_cors import CORS
import os
import sys

# Add backend directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from config import get_config, config_by_name
from database import connect_to_mongodb, initialize_indexes, health_check, close_mongodb_connection
from firebase import initialize_firebase
from auth import auth_bp

# Import route blueprints
try:
    from routes.notices import notices_bp
    from routes.assignments import assignments_bp
    from routes.materials import materials_bp
    from routes.faqs import faqs_bp
    from routes.users import users_bp
    from routes.notifications import notifications_bp
    ROUTES_AVAILABLE = True
except ImportError as e:
    print(f"Warning: Some routes could not be imported: {e}")
    ROUTES_AVAILABLE = False


def create_app(config_name=None):
    """
    Create and configure the Flask application
    """
    # Initialize Flask
    app = Flask(__name__)
    
    # Load configuration
    if config_name:
        config = config_by_name.get(config_name, DevelopmentConfig)
    else:
        config = get_config()
    
    app.config['SECRET_KEY'] = config.JWT_SECRET_KEY
    app.config['DEBUG'] = config.FLASK_DEBUG
    
    # Configure CORS
    cors_origins = config.CORS_ORIGINS.split(',') if config.CORS_ORIGINS != '*' else ['*']
    CORS(app, origins=cors_origins, supports_credentials=True)
    
    # Register blueprints
    app.register_blueprint(auth_bp)
    
    if ROUTES_AVAILABLE:
        try:
            app.register_blueprint(notices_bp)
            app.register_blueprint(assignments_bp)
            app.register_blueprint(materials_bp)
            app.register_blueprint(faqs_bp)
            app.register_blueprint(users_bp)
            app.register_blueprint(notifications_bp)
        except Exception as e:
            print(f"Warning: Could not register some blueprints: {e}")
    
    # Health check endpoint
    @app.route('/health', methods=['GET'])
    def health():
        """Health check endpoint"""
        mongodb_status, mongodb_message = health_check()
        
        return jsonify({
            'status': 'healthy' if mongodb_status else 'degraded',
            'mongodb': {
                'connected': mongodb_status,
                'message': mongodb_message
            },
            'firebase': {
                'enabled': initialize_firebase() is not None
            }
        }), 200 if mongodb_status else 503
    
    # Root endpoint
    @app.route('/', methods=['GET'])
    def root():
        """Root endpoint"""
        return jsonify({
            'name': 'SRIMCA AI Backend',
            'version': '1.0.0',
            'status': 'running',
            'endpoints': {
                'auth': '/api',
                'notices': '/api/notices',
                'assignments': '/api/assignments',
                'materials': '/api/materials',
                'faqs': '/api/faqs',
                'users': '/api/users',
                'health': '/health'
            }
        }), 200
    
    # Error handlers
    @app.errorhandler(404)
    def not_found(error):
        return jsonify({'error': 'Endpoint not found'}), 404
    
    @app.errorhandler(500)
    def internal_error(error):
        return jsonify({'error': 'Internal server error'}), 500
    
    @app.before_request
    def before_request():
        """Log requests"""
        print(f"{request.method} {request.path}")
    
    return app


# Create the app
app = create_app()

# Initialize connections on startup
def initialize_app():
    """Initialize database and Firebase connections"""
    print("Initializing SRIMCA AI Backend...")
    
    # Connect to MongoDB
    try:
        connect_to_mongodb()
        initialize_indexes()
        print("✅ MongoDB Atlas connected")
    except Exception as e:
        print(f"❌ MongoDB connection failed: {e}")
    
    # Initialize Firebase
    try:
        initialize_firebase()
        print("✅ Firebase initialized")
    except Exception as e:
        print(f"⚠️ Firebase initialization skipped: {e}")


# Run initialization
if __name__ == '__main__':
    initialize_app()
    
    config = get_config()
    print(f"\n🚀 Server running on http://0.0.0.0:{config.PORT}")
    print(f"📚 API Documentation available at http://0.0.0.0:{config.PORT}/")
    
    app.run(host='0.0.0.0', port=config.PORT, debug=config.FLASK_DEBUG)


# For gunicorn/WSGI
application = app

# Cleanup on exit
import atexit
atexit.register(close_mongodb_connection)
