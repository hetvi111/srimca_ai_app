from database import get_database, Collections
from datetime import datetime

db = get_database()
coll = db[Collections.VISITORS]

samples = [
    {
        'name': 'Gurang pandiya',
        'email': 'gurang@gmail.com',
        'phone': '1234567890',
        'purpose': 'Parent meeting',
        'status': 'pending',
        'visit_date': '2024-10-04',
        'entry_time': '09:00',
        'exit_time': '',
        'created_at': datetime.utcnow()
    },
    {
        'name': 'Tanvi sharma',
        'email': 'tanvi@gmail.com',
        'phone': '0987654321',
        'purpose': 'Academic inquiry',
        'status': 'approved',
        'visit_date': '2024-10-03',
        'entry_time': '14:30',
        'exit_time': '15:45',
        'created_at': datetime.utcnow()
    },
]

for sample in samples:
    if coll.count_documents({'email': sample['email']}) == 0:
        coll.insert_one(sample)
        print(f'Added: {sample["name"]}')

print('Sample visitors created!')
print('Run: cd backend && python create_sample_visitors.py')

