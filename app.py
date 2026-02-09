from flask import Flask, request, jsonify
from flask_cors import CORS
from pymongo import MongoClient
from bson import ObjectId
from werkzeug.security import generate_password_hash, check_password_hash
import datetime
import os

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})

# ------------------- MongoDB Atlas Connection -------------------

# OPTION 1 (Recommended): Use environment variable
# export MONGO_URI="your_mongodb_atlas_uri"

MONGO_URI = os.getenv(
    "MONGO_URI",
    "mongodb+srv://n8n:n8nconnection@cluster0.guplsjx.mongodb.net/srimca_ai?appName=Cluster0"
)

client = MongoClient(MONGO_URI)
db = client["srimca_ai"]

users = db["users"]
uploads = db["uploads"]
ai_content = db["content"]
faqs = db["faqs"]
alerts = db["alerts"]
reports = db["reports"]
security = db["security"]

# ------------------- Registration -------------------
@app.route("/register", methods=["POST"])
def register():
    data = request.json

    email = data.get("email")
    password = data.get("password")
    name = data.get("name")
    role = data.get("role")
    enrollment = data.get("enrollment")
    staffId = data.get("staffId")

    if not email or not password or not role:
        return jsonify({"success": False, "message": "Missing required fields"}), 400

    if users.find_one({"email": email}):
        return jsonify({"success": False, "message": "Email already registered"}), 409

    hashed_password = generate_password_hash(password)

    user_doc = {
        "email": email,
        "password": hashed_password,
        "name": name,
        "role": role,
        "enrollment": enrollment,
        "staffId": staffId,
        "created_at": datetime.datetime.utcnow(),
        "status": "Active"
    }

    users.insert_one(user_doc)

    return jsonify({"success": True, "message": "Registration successful"}), 201


# ------------------- Login -------------------
@app.route("/login", methods=["POST"])
def login():
    data = request.json

    email = data.get("email")
    password = data.get("password")
    role = data.get("role")

    if not email or not password or not role:
        return jsonify({"success": False, "message": "Missing credentials"}), 400

    user = users.find_one({"email": email, "role": role})

    if not user:
        return jsonify({"success": False, "message": "User not found"}), 404

    if not user.get("password"):
        return jsonify({"success": False, "message": "Password not set"}), 400

    if check_password_hash(user["password"], password):
        return jsonify({
            "success": True,
            "message": "Login successful",
            "user": {
                "id": str(user["_id"]),
                "name": user.get("name"),
                "email": user.get("email"),
                "role": user.get("role")
            }
        }), 200

    return jsonify({"success": False, "message": "Invalid password"}), 401


# ------------------- User Management -------------------
@app.route("/users", methods=["GET"])
def get_users():
    user_list = list(users.find({}, {"password": 0}))
    for u in user_list:
        u["_id"] = str(u["_id"])
    return jsonify(user_list), 200


@app.route("/users", methods=["POST"])
def add_user():
    data = request.json

    if users.find_one({"email": data.get("email")}):
        return jsonify({"success": False, "message": "Email already exists"}), 409

    user_doc = {
        "name": data.get("name"),
        "email": data.get("email"),
        "role": data.get("role"),
        "status": data.get("status", "Active"),
        "created_at": datetime.datetime.utcnow()
    }

    result = users.insert_one(user_doc)
    return jsonify({"success": True, "id": str(result.inserted_id)}), 201


@app.route("/users/<user_id>", methods=["PUT"])
def update_user(user_id):
    data = request.json
    users.update_one(
        {"_id": ObjectId(user_id)},
        {"$set": data}
    )
    return jsonify({"success": True, "message": "User updated"}), 200


@app.route("/users/<user_id>", methods=["DELETE"])
def delete_user(user_id):
    users.delete_one({"_id": ObjectId(user_id)})
    return jsonify({"success": True, "message": "User deleted"}), 200


# ------------------- Uploads -------------------
@app.route("/uploads", methods=["GET"])
def get_uploads():
    upload_list = list(uploads.find({}))
    for u in upload_list:
        u["_id"] = str(u["_id"])
    return jsonify(upload_list), 200


@app.route("/uploads", methods=["POST"])
def add_upload():
    data = request.json
    uploads.insert_one({
        "name": data.get("name"),
        "uploaded_time": data.get("uploaded_time"),
        "status": "Pending",
        "created_at": datetime.datetime.utcnow()
    })
    return jsonify({"success": True}), 201


@app.route("/uploads/approve/<upload_id>", methods=["POST"])
def approve_upload(upload_id):
    uploads.update_one({"_id": ObjectId(upload_id)}, {"$set": {"status": "Approved"}})
    return jsonify({"success": True}), 200


@app.route("/uploads/reject/<upload_id>", methods=["POST"])
def reject_upload(upload_id):
    uploads.update_one({"_id": ObjectId(upload_id)}, {"$set": {"status": "Rejected"}})
    return jsonify({"success": True}), 200


# ------------------- FAQs -------------------
@app.route("/faqs", methods=["GET"])
def get_faqs():
    faq_list = list(faqs.find({}))
    for f in faq_list:
        f["_id"] = str(f["_id"])
    return jsonify(faq_list), 200


@app.route("/faqs", methods=["POST"])
def add_faq():
    data = request.json
    faqs.insert_one({
        "question": data.get("question"),
        "created_at": datetime.datetime.utcnow()
    })
    return jsonify({"success": True}), 201


# ------------------- Dashboard Stats -------------------
@app.route("/dashboard/stats", methods=["GET"])
def get_dashboard_stats():
    stats = {
        "total_users": users.count_documents({}),
        "total_uploads": uploads.count_documents({}),
        "pending_uploads": uploads.count_documents({"status": "Pending"}),
        "approved_uploads": uploads.count_documents({"status": "Approved"}),
        "rejected_uploads": uploads.count_documents({"status": "Rejected"}),
    }
    return jsonify(stats), 200


# ------------------- Health Check -------------------
@app.route("/")
def home():
    return "Flask Backend is Running!"


# ------------------- Run Server -------------------
if __name__ == "__main__":
    port = int(os.environ.get('PORT', 5000))
    app.run(host="0.0.0.0", port=port, debug=False)
