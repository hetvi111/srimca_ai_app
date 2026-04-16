"""
Database connection and helper functions for MongoDB Atlas
"""

from pymongo import MongoClient
from pymongo.errors import ConnectionFailure, ServerSelectionTimeoutError
from config import get_config
import sys
import io

# Fix Unicode encoding for Windows
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

# Global database connection
_client = None
_db = None


def connect_to_mongodb():
    """
    Connect to MongoDB Atlas and return the database connection
    """
    global _client, _db
    
    config = get_config()
    
    # Debug: Print the URI being used (masked for security)
    uri = config.MONGODB_URI
    if uri:
        # Mask password in URI for logging
        masked_uri = uri
        if '@' in uri:
            try:
                parts = uri.split('@')
                creds = parts[0].split('://')[1]
                masked_uri = uri.replace(creds, '****:****')
            except:
                pass
        print(f"Connecting to MongoDB: {masked_uri}")
    else:
        print("ERROR: MONGODB_URI is not set!")
        raise Exception("MONGODB_URI environment variable is not set. Please check your .env file.")
    
    try:
        # Create MongoDB client with proper settings
        _client = MongoClient(
            uri,
            serverSelectionTimeoutMS=5000,  # 5 seconds timeout
            connectTimeoutMS=10000,
            retryWrites=True,
            retryReads=True
        )
        
        # Get database
        _db = _client[config.MONGODB_DB_NAME]
        
        # Test connection
        _client.admin.command('ping')
        
        print(f"✅ Successfully connected to MongoDB Atlas: {config.MONGODB_DB_NAME}")
        return _db
        
    except ServerSelectionTimeoutError as e:
        print(f"❌ MongoDB connection timeout: {e}")
        raise Exception("Failed to connect to MongoDB Atlas. Please check your connection string.")
    except ConnectionFailure as e:
        print(f"❌ MongoDB connection failed: {e}")
        raise Exception("Failed to connect to MongoDB Atlas.")
    except Exception as e:
        print(f"❌ Unexpected error connecting to MongoDB: {e}")
        raise


def get_database():
    """
    Get the MongoDB database instance
    Creates connection if not already connected
    """
    global _db
    
    if _db is None:
        _db = connect_to_mongodb()
    
    return _db


def get_collection(collection_name: str):
    """
    Get a specific collection from the database
    """
    db = get_database()
    return db[collection_name]


# Collection names as constants
class Collections:
    USERS = 'users'
    NOTICES = 'notices'
    ASSIGNMENTS = 'assignments'
    MATERIALS = 'materials'
    FAQS = 'faqs'
    AI_QUERIES = 'ai_queries'
    SESSIONS = 'sessions'
    NOTIFICATIONS = 'notifications'
    VISITORS = 'visitors'
    QUERIES = 'queries'
    SYSTEM_META = 'system_meta'
    PASSWORD_RESET_REQUESTS = 'password_requests'
    VISITOR_LOGS = 'visitor_logs'


def close_mongodb_connection():
    """
    Close the MongoDB connection
    """
    global _client
    
    if _client:
        _client.close()
        print("MongoDB connection closed")


def initialize_collections():
    """
    Ensure required MongoDB collections exist at startup
    """
    db = get_database()
    existing_collections = set(db.list_collection_names())
    required_collections = [
        Collections.USERS,
        Collections.NOTICES,
        Collections.ASSIGNMENTS,
        Collections.MATERIALS,
        Collections.FAQS,
        Collections.AI_QUERIES,
        Collections.SESSIONS,
        Collections.NOTIFICATIONS,
        Collections.VISITORS,
        Collections.QUERIES,
    Collections.SYSTEM_META,
        Collections.PASSWORD_RESET_REQUESTS,
    ]

    for collection_name in required_collections:
        if collection_name not in existing_collections:
            db.create_collection(collection_name)

    print("Database collections ensured successfully")


# Initialize database with indexes
def initialize_indexes():
    """
    Create necessary indexes for efficient querying
    """
    db = get_database()
    
    # Users collection indexes
    db[Collections.USERS].create_index('email', unique=True)
    db[Collections.USERS].create_index('role')
    
    # Notices collection indexes
    db[Collections.NOTICES].create_index('created_at')
    db[Collections.NOTICES].create_index('faculty_id')
    
    # Assignments collection indexes
    db[Collections.ASSIGNMENTS].create_index('due_date')
    db[Collections.ASSIGNMENTS].create_index('faculty_id')
    
    # Materials collection indexes
    db[Collections.MATERIALS].create_index('subject')
    db[Collections.MATERIALS].create_index('faculty_id')
    
    # AI Queries indexes
    db[Collections.AI_QUERIES].create_index('user_id')
    db[Collections.AI_QUERIES].create_index('created_at')

    # FAQs indexes
    db[Collections.FAQS].create_index('created_at')
    db[Collections.FAQS].create_index('created_by')

    # Notifications indexes
    db[Collections.NOTIFICATIONS].create_index('created_at')
    db[Collections.NOTIFICATIONS].create_index('target_role')
    db[Collections.NOTIFICATIONS].create_index('sender_role')
    db[Collections.NOTIFICATIONS].create_index('related_id')

    # Visitors indexes
    db[Collections.VISITORS].create_index('email')
    db[Collections.VISITORS].create_index('status')
    db[Collections.VISITORS].create_index('created_at')

    # Sessions and queries indexes
    db[Collections.SESSIONS].create_index('user_id')
    db[Collections.SESSIONS].create_index('created_at')
    db[Collections.QUERIES].create_index('created_at')
    
    # Password reset requests indexes
    db[Collections.PASSWORD_RESET_REQUESTS].create_index('email')
    db[Collections.PASSWORD_RESET_REQUESTS].create_index('status')
    db[Collections.PASSWORD_RESET_REQUESTS].create_index('created_at')
    
    print("Database indexes created successfully")


def health_check():
    """
    Check if MongoDB connection is healthy
    """
    try:
        db = get_database()
        db.command('ping')
        return True, "MongoDB connection is healthy"
    except Exception as e:
        return False, str(e)
