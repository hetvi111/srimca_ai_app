"""
SRIMCA AI Backend - Main Application Entry Point
This is the main Flask application that registers all blueprints and routes.
"""

from flask import Flask, jsonify
from flask_cors import CORS
import os

# Import config
from config import get_config

# Import database initialization
from database import initialize_indexes

# Import auth blueprint
from auth import auth_bp

# Import all route blueprints
from routes.notices import notices_bp
from routes.assignments import assignments_bp
from routes.materials import materials_bp
from routes.faqs import faqs_bp
from routes.users import users_bp
from routes.admin import admin_bp
from routes.ai import ai_bp
# from routes.notifications import notifications_bp  # Temporarily disabled due to Flask 3.0 issue
from routes.notifications import notifications_bp


def create_app(config_name=None):
    """Application factory for creating Flask app"""
    app = Flask(__name__)
    
    # Load configuration
    if config_name is None:
        config_name = os.getenv('FLASK_ENV', 'development')
    config = get_config()
    
    app.config['SECRET_KEY'] = config.JWT_SECRET_KEY
    app.config['MONGODB_URI'] = config.MONGODB_URI
    app.config['MONGODB_DB_NAME'] = config.MONGODB_DB_NAME
    
    # Enable CORS
    CORS(app, origins=config.CORS_ORIGINS, supports_credentials=True)
    
    # Initialize database
    initialize_indexes()
    
    # Register blueprints
    app.register_blueprint(auth_bp)
    app.register_blueprint(notices_bp)
    app.register_blueprint(assignments_bp)
    app.register_blueprint(materials_bp)
    app.register_blueprint(faqs_bp)
    app.register_blueprint(users_bp)
    app.register_blueprint(admin_bp)
    app.register_blueprint(ai_bp)
    app.register_blueprint(notifications_bp)
    
    # Health check route
    @app.route('/')
    def index():
        return jsonify({
            'message': 'Welcome to SRIMCA AI Backend',
            'status': 'running',
            'version': '1.0.0'
        })
    
    @app.route('/health')
    def health():
        return jsonify({
            'status': 'healthy',
            'database': 'connected'
        })
    
    # Error handlers
    @app.errorhandler(404)
    def not_found(error):
        return jsonify({'error': 'Resource not found'}), 404
    
    @app.errorhandler(500)
    def internal_error(error):
        return jsonify({'error': 'Internal server error'}), 500
    
    return app


# Create the application instance
app = create_app()


if __name__ == '__main__':
    config = get_config()
    port = config.PORT
    debug = config.FLASK_DEBUG
    
    print(f"Starting SRIMCA AI Backend on port {port}")
    app.run(host='0.0.0.0', port=port, debug=debug)
