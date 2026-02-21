"""
Configuration file for SRIMCA AI Backend
Handles MongoDB Atlas and Firebase configuration
"""

import os
from dotenv import load_dotenv

# Get the directory where this config file is located
config_dir = os.path.dirname(os.path.abspath(__file__))
# Load environment variables from the backend .env file
load_dotenv(os.path.join(config_dir, '.env'))


class Config:
    """Main configuration class"""
    
    # MongoDB Atlas Configuration
    MONGODB_URI = os.getenv('MONGODB_URI', 'mongodb+srv://n8n:n8nconnection@cluster0.guplsjx.mongodb.net')
    MONGODB_DB_NAME = os.getenv('MONGODB_DB_NAME', 'srimca_ai')
    
    # Firebase Configuration
    FIREBASE_PROJECT_ID = os.getenv('FIREBASE_PROJECT_ID', 'srimcaai')
    FIREBASE_PRIVATE_KEY = os.getenv('FIREBASE_PRIVATE_KEY', '').replace('\\n', '\n')
    FIREBASE_CLIENT_EMAIL = os.getenv('FIREBASE_CLIENT_EMAIL', '')
    
    # JWT Configuration
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'your_super_secret_jwt_key_change_in_production')
    JWT_EXPIRATION_HOURS = int(os.getenv('JWT_EXPIRATION_HOURS', '24'))
    
    # Flask Configuration
    FLASK_ENV = os.getenv('FLASK_ENV', 'development')
    FLASK_DEBUG = os.getenv('FLASK_DEBUG', 'True').lower() == 'true'
    PORT = int(os.getenv('PORT', '5000'))
    
    # CORS Configuration
    CORS_ORIGINS = os.getenv('CORS_ORIGINS', '*')


class DevelopmentConfig(Config):
    """Development configuration"""
    DEBUG = True
    FLASK_ENV = 'development'


class ProductionConfig(Config):
    """Production configuration"""
    DEBUG = False
    FLASK_ENV = 'production'


class TestingConfig(Config):
    """Testing configuration"""
    TESTING = True
    MONGODB_URI = 'mongodb+srv://n8n:n8nconnection@cluster0.guplsjx.mongodb.net'


# Configuration dictionary for easy switching
config_by_name = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig
}


def get_config():
    """Get the configuration based on environment"""
    env = os.getenv('FLASK_ENV', 'development')
    return config_by_name.get(env, DevelopmentConfig)
