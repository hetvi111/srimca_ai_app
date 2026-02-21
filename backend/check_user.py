import sys
sys.path.insert(0, '.')
print("Starting...", flush=True)

from database import connect_to_mongodb, get_collection, Collections
print("Connecting to DB...", flush=True)
db = connect_to_mongodb()
print("Connected", flush=True)
users = db[Collections.USERS]
print("Fetching user...", flush=True)
user = users.find_one({'email': 'hetvi@student.srimca.edu'})
if user:
    print('User found:', user.get('email'), 'Role:', user.get('role'), flush=True)
    print('Password hash exists:', bool(user.get('password')), flush=True)
else:
    print('User not found', flush=True)
