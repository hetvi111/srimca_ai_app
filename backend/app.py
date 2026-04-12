"""
SRIMCA AI Backend - Main Application Entry Point
This is the main Flask application that registers all blueprints and routes.
"""

from flask import Flask, jsonify
from flask_cors import CORS
import os
import threading
import traceback

# Import config
from config import get_config

# Import database initialization
from database import initialize_collections, initialize_indexes

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
from routes.notifications import notifications_bp


def initialize_database_async():
    """Initialize database resources without blocking app startup."""
    try:
        initialize_collections()
        initialize_indexes()
        print("Database initialization completed")
    except Exception as e:
        # Keep the API process alive even if database init fails at startup.
        print(f"Database initialization warning: {e}")


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
    
    # Initialize database in a background thread so the server can bind quickly.
    db_init_thread = threading.Thread(target=initialize_database_async, daemon=True)
    db_init_thread.start()
    
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
    
    @app.route('/api/health')
    def api_health():
        return jsonify({
            'status': 'healthy',
            'database': 'connected',
            'api': 'ok'
        })
    
    # Error handlers
    @app.errorhandler(404)
    def not_found(error):
        return jsonify({'error': 'Resource not found'}), 404
    
    @app.errorhandler(500)
    def internal_error(error):
        # Log full traceback so Render/local logs show what failed.
        try:
            app.logger.error("HTTP 500 error:\n%s", "".join(traceback.format_exception(type(error), error, error.__traceback__)))
        except Exception:
            print("HTTP 500 error (failed to format traceback).")
            print(error)
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
