"""
Migration Script: Normalize Existing Database

This script migrates existing user data from the monolithic 'users' collection
to the normalized collections:
- users (authentication only)
- user_profiles (personal info)
- students (student-specific data)
- faculty (faculty-specific data)

IMPORTANT: Run this script ONCE to migrate existing data.
After migration, the system will work with both old and new data structures.
"""

import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

from pymongo import MongoClient
from bson import ObjectId
from datetime import datetime
import bcrypt

# Import configuration
try:
    from config import get_config
except ImportError:
    print("Warning: Could not import config, using environment variables directly")
    import os
    def get_config():
        class Config:
            MONGODB_URI = os.environ.get('MONGODB_URI', '')
            MONGODB_DB_NAME = os.environ.get('MONGODB_DB_NAME', 'srimca_ai')
        return Config()


def migrate_users():
    """
    Main migration function
    """
    config = get_config()
    
    if not config.MONGODB_URI:
        print("ERROR: MONGODB_URI not set!")
        return False
    
    try:
        # Connect to MongoDB
        client = MongoClient(
            config.MONGODB_URI,
            serverSelectionTimeoutMS=5000
        )
        db = client[config.MONGODB_DB_NAME]
        
        print(f"Connected to MongoDB: {config.MONGODB_DB_NAME}")
        
        # Get collections
        users_col = db['users']
        profiles_col = db['user_profiles']
        students_col = db['students']
        faculty_col = db['faculty']
        
        # Check if migration already done
        if profiles_col.count_documents({}) > 0 or students_col.count_documents({}) > 0:
            print("\n⚠️  Migration appears to already be done!")
            response = input("Do you want to re-run migration? (yes/no): ")
            if response.lower() != 'yes':
                print("Migration cancelled.")
                return True
        
        # Get all users
        all_users = list(users_col.find({}))
        print(f"\nFound {len(all_users)} users to migrate...")
        
        migrated_count = 0
        skipped_count = 0
        
        for user in all_users:
            user_id = str(user.get('_id'))
            role = user.get('role', '').lower()
            
            try:
                # 1. Clean up user document (keep only auth data)
                users_col.update_one(
                    {'_id': ObjectId(user_id)},
                    {'$set': {'updated_at': datetime.utcnow()}}
                )
                
                # Remove profile fields from users collection (keep for backward compat initially)
                # We'll mark them as "migrated" instead of deleting
                
                # 2. Extract profile data to user_profiles
                profile_data = user.get('profile', {})
                if profile_data or user.get('mobile') or user.get('address'):
                    profile_doc = {
                        'user_id': user_id,
                        'phone': user.get('mobile', profile_data.get('phone', '')),
                        'address': user.get('address', profile_data.get('address', '')),
                        'created_at': user.get('created_at', datetime.utcnow()),
                        'updated_at': datetime.utcnow(),
                        'migrated_from': 'users.profile'
                    }
                    
                    # Check if profile already exists
                    existing_profile = profiles_col.find_one({'user_id': user_id})
                    if not existing_profile:
                        profiles_col.insert_one(profile_doc)
                        print(f"  ✓ Created profile for user {user_id}")
                
                # 3. Extract student data to students collection
                if role == 'student':
                    student_data = {
                        'user_id': user_id,
                        'semester': user.get('semester', profile_data.get('semester', '')),
                        'department': user.get('department', profile_data.get('department', '')),
                        'enrollment_number': user.get('enrollment', profile_data.get('enrollment_number', '')),
                        'dob': user.get('dob', ''),
                        'created_at': user.get('created_at', datetime.utcnow()),
                        'updated_at': datetime.utcnow(),
                        'migrated_from': 'users'
                    }
                    
                    # Check if student already exists
                    existing_student = students_col.find_one({'user_id': user_id})
                    if not existing_student:
                        students_col.insert_one(student_data)
                        print(f"  ✓ Created student record for user {user_id}")
                
                # 4. Extract faculty data to faculty collection
                elif role == 'faculty':
                    faculty_data = {
                        'user_id': user_id,
                        'department': user.get('department', ''),
                        'designation': user.get('designation', ''),
                        'created_at': user.get('created_at', datetime.utcnow()),
                        'updated_at': datetime.utcnow(),
                        'migrated_from': 'users'
                    }
                    
                    # Check if faculty already exists
                    existing_faculty = faculty_col.find_one({'user_id': user_id})
                    if not existing_faculty:
                        faculty_col.insert_one(faculty_data)
                        print(f"  ✓ Created faculty record for user {user_id}")
                
                migrated_count += 1
                
            except Exception as e:
                print(f"  ✗ Error migrating user {user_id}: {e}")
                skipped_count += 1
        
        # Mark all users as migrated
        users_col.update_many(
            {'migrated_to_normalized': {'$ne': True}},
            {'$set': {'migrated_to_normalized': True, 'migration_date': datetime.utcnow()}}
        )
        
        print(f"\n✅ Migration complete!")
        print(f"   - Migrated: {migrated_count}")
        print(f"   - Skipped: {skipped_count}")
        
        # Create indexes
        print("\n📇 Creating indexes...")
        profiles_col.create_index('user_id', unique=True)
        students_col.create_index('user_id', unique=True)
        students_col.create_index('enrollment_number', unique=True)
        faculty_col.create_index('user_id', unique=True)
        print("✅ Indexes created")
        
        return True
        
    except Exception as e:
        print(f"❌ Migration failed: {e}")
        return False


def verify_migration():
    """
    Verify the migration was successful
    """
    config = get_config()
    
    try:
        client = MongoClient(config.MONGODB_URI, serverSelectionTimeoutMS=5000)
        db = client[config.MONGODB_DB_NAME]
        
        print("\n📊 Migration Verification:")
        print(f"   Users: {db['users'].count_documents({})}")
        print(f"   User Profiles: {db['user_profiles'].count_documents({})}")
        print(f"   Students: {db['students'].count_documents({})}")
        print(f"   Faculty: {db['faculty'].count_documents({})}")
        
        # Show sample data
        print("\n📝 Sample User (should have minimal fields):")
        sample_user = db['users'].find_one()
        if sample_user:
            print(f"   _id: {sample_user.get('_id')}")
            print(f"   name: {sample_user.get('name')}")
            print(f"   email: {sample_user.get('email')}")
            print(f"   role: {sample_user.get('role')}")
            print(f"   migrated_to_normalized: {sample_user.get('migrated_to_normalized', False)}")
        
        return True
        
    except Exception as e:
        print(f"❌ Verification failed: {e}")
        return False


def rollback_migration():
    """
    Rollback migration (if needed)
    """
    config = get_config()
    
    response = input("⚠️  Are you sure you want to ROLLBACK? This will delete normalized collections! (yes/no): ")
    if response.lower() != 'yes':
        print("Rollback cancelled.")
        return
    
    try:
        client = MongoClient(config.MONGODB_URI, serverSelectionTimeoutMS=5000)
        db = client[config.MONGODB_DB_NAME]
        
        # Drop normalized collections
        db['user_profiles'].drop()
        db['students'].drop()
        db['faculty'].drop()
        
        # Remove migration markers
        db['users'].update_many({}, {'$unset': {'migrated_to_normalized': '', 'migration_date': ''}})
        
        print("✅ Rollback complete!")
        
    except Exception as e:
        print(f"❌ Rollback failed: {e}")


if __name__ == '__main__':
    print("=" * 60)
    print("SRIMCA AI - Database Normalization Migration")
    print("=" * 60)
    print("\nThis script will:")
    print("1. Create normalized collections (user_profiles, students, faculty)")
    print("2. Move existing user data to appropriate collections")
    print("3. Mark users as migrated for backward compatibility")
    print("\nThe original 'users' collection will NOT be deleted.")
    print("=" * 60)
    
    print("\nChoose action:")
    print("1. Run migration")
    print("2. Verify migration")
    print("3. Rollback migration")
    print("4. Exit")
    
    choice = input("\nEnter choice (1-4): ")
    
    if choice == '1':
        migrate_users()
    elif choice == '2':
        verify_migration()
    elif choice == '3':
        rollback_migration()
    else:
        print("Exiting...")

