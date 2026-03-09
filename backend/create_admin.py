"""
Script to create admin user in MongoDB
Run: python backend/create_admin.py
"""

import bcrypt
from datetime import datetime
from database import get_collection, Collections

def create_admin_user():
    """Create admin user in MongoDB"""
    
    # Admin credentials - CHANGE THESE VALUES
    admin_email = "admin@srimca.edu"
    admin_password = "admin123"  # Password: admin123
    admin_name = "Admin"
    admin_mobile = "1234567890"
    
    # Hash the password
    hashed = bcrypt.hashpw(admin_password.encode('utf-8'), bcrypt.gensalt())
    hashed_password = hashed.decode('utf-8')
    
    # Get users collection
    users = get_collection(Collections.USERS)
    
    # Check if admin already exists
    existing = users.find_one({'email': admin_email})
    if existing:
        print(f"Admin user already exists: {admin_email}")
        return
    
    # Create admin document
    admin_doc = {
        'name': admin_name,
        'email': admin_email.lower(),
        'password': hashed_password,
        'role': 'admin',
        'mobile': admin_mobile,
        'is_active': True,
        'created_at': datetime.utcnow(),
        'updated_at': datetime.utcnow(),
        'last_login': None
    }
    
    # Insert into database
    result = users.insert_one(admin_doc)
    print(f"Admin user created successfully!")
    print(f"Email: {admin_email}")
    print(f"Password: {admin_password}")
    print(f"User ID: {result.inserted_id}")

if __name__ == "__main__":
    create_admin_user()
