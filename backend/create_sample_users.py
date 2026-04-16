"""
Create 1 Admin, 1 Student, 1 Faculty, and 1 Visitor user in MongoDB.

Run:
  cd backend
  python create_sample_users.py
"""

from datetime import datetime
import bcrypt

from database import get_collection, Collections
from config import get_config


def _upsert_user_by_email(user_doc: dict, plain_password: str) -> str:
    users = get_collection(Collections.USERS)
    existing = users.find_one({"email": user_doc["email"]})
    if existing:
        return str(existing.get("_id", ""))

    hashed_password = bcrypt.hashpw(plain_password.encode("utf-8"), bcrypt.gensalt())
    user_doc["password"] = hashed_password.decode("utf-8")
    result = users.insert_one(user_doc)
    return str(result.inserted_id)


def main():
    # Load env (.env) before DB connect
    _ = get_config()

    now = datetime.utcnow()

    samples = [
        (
            {
                "name": "Admin User",
                "email": "admin@srimca.edu",
                "role": "admin",
                "is_active": True,
                "created_at": now,
                "updated_at": now,
                "last_login": None,
                "mobile": "9999999999",
                "profile": {
                    "phone": "9999999999",
                    "address": "",
                    "semester": "",
                    "department": "Administration",
                    "enrollment_number": "",
                },
            },
            "admin123",
        ),
        (
            {
                "name": "Student User",
                "email": "student@srimca.edu",
                "role": "student",
                "is_active": True,
                "created_at": now,
                "updated_at": now,
                "last_login": None,
                "mobile": "8888888888",
                "enrollment": "MCA2026SRIMCA001",
                "dob": "2004-01-15",
                "semester": "2",
                "department": "mca",
                "profile": {
                    "phone": "8888888888",
                    "address": "",
                    "semester": "2",
                    "department": "mca",
                    "enrollment_number": "MCA2026SRIMCA001",
                },
            },
            "student123",
        ),
        (
            {
                "name": "Faculty User",
                "email": "faculty2@srimca.edu",
                "role": "faculty",
                "is_active": True,
                "created_at": now,
                "updated_at": now,
                "last_login": None,
                "mobile": "7777777777",
                "department": "mca",
                "designation": "Assistant Professor",
                "profile": {
                    "phone": "7777777777",
                    "address": "",
                    "semester": "",
                    "department": "mca",
                    "enrollment_number": "",
                },
            },
            "faculty123",
        ),
        (
            {
                "name": "Visitor User",
                "email": "visitor@srimca.edu",
                "role": "visitor",
                "is_active": True,
                "created_at": now,
                "updated_at": now,
                "last_login": None,
                "mobile": "6666666666",
                "purpose": "admission",
                "visit_date": now.isoformat(),
                "approval_status": "pending",
                "profile": {
                    "phone": "6666666666",
                    "address": "",
                    "semester": "",
                    "department": "",
                    "enrollment_number": "",
                },
            },
            "visitor123",
        ),
    ]

    print("Creating sample users (upsert by email)...")
    for doc, pwd in samples:
        _id = _upsert_user_by_email(doc, pwd)
        print(f"✅ {doc['role']}: {doc['email']}  _id={_id}")

    print("\nLogin credentials:")
    print("  admin@srimca.edu / admin123")
    print("  student@srimca.edu / student123")
    print("  faculty2@srimca.edu / faculty123")
    print("  visitor@srimca.edu / visitor123")


if __name__ == "__main__":
    main()

