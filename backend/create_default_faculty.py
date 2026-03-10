"""
Create a default faculty user in the database
Run this script to add a default faculty member
"""

import bcrypt
from datetime import datetime
from database import get_collection, Collections
from config import get_config

def create_default_faculty():
    """
    Create a default faculty user in the database
    """
    print("Creating default faculty user...")
    
    # Get the users collection
    users = get_collection(Collections.USERS)
    
    # Default faculty credentials
    faculty_data = {
        'name': 'Dr. Faculty',
        'email': 'faculty@srimca.edu',
        'password': 'faculty123',  # Will be hashed
        'role': 'faculty',
        'mobile': '9876543210',
        'department': 'Computer Science',
        'designation': 'Professor',
        'is_active': True,
        'created_at': datetime.utcnow(),
        'updated_at': datetime.utcnow(),
        'last_login': None,
        'profile': {
            'phone': '9876543210',
            'address': '',
            'semester': '',
            'department': 'Computer Science',
            'enrollment_number': ''
        }
    }
    
    # Check if faculty already exists
    existing = users.find_one({'email': faculty_data['email']})
    if existing:
        print(f"Faculty with email {faculty_data['email']} already exists!")
        print(f"Faculty ID: {existing['_id']}")
        return
    
    # Hash password
    hashed_password = bcrypt.hashpw(faculty_data['password'].encode('utf-8'), bcrypt.gensalt())
    faculty_data['password'] = hashed_password.decode('utf-8')
    
    # Insert into database
    result = users.insert_one(faculty_data)
    
    print(f"✅ Default faculty created successfully!")
    print(f"Faculty ID: {result.inserted_id}")
    print(f"Email: {faculty_data['email']}")
    print(f"Password: {faculty_data['password'][:20]}...")
    print("\nYou can login with:")
    print(f"  Email: {faculty_data['email']}")
    print(f"  Password: faculty123")


if __name__ == '__main__':
    # Initialize config to load environment variables
    config = get_config()
    
    # Try to connect and create the faculty
    try:
        create_default_faculty()
    except Exception as e:
        print(f"Error creating faculty: {e}")
        print("Make sure MongoDB is running and accessible!")

