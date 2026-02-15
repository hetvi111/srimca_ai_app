import os
import datetime
from flask import Flask, request, jsonify
from flask_cors import CORS
from pymongo import MongoClient
from bson import ObjectId

# ================== CONFIG ==================
MONGODB_URI = os.environ.get("MONGODB_URI", "mongodb+srv://n8n:n8nconnection@cluster0.guplsjx.mongodb.net/?appName=Cluster0")
DB_NAME = os.environ.get("DB_NAME", "srimca_ai")
PORT = int(os.environ.get("PORT", 5000))

app = Flask(__name__)
CORS(app)

# ================== MONGODB ==================
try:
    client = MongoClient(MONGODB_URI)
    db = client[DB_NAME]
    client.admin.command("ping")
    print("[OK] MongoDB Atlas Connected")
except Exception as e:
    print("[ERROR] MongoDB connection failed:", e)
    exit(1)

# ================== HELPERS ==================
def serialize(doc):
    doc["_id"] = str(doc["_id"])
    return doc

# ================== HEALTH ==================
@app.route("/")
def home():
    return jsonify({
        "status": "Backend Running",
        "database": "MongoDB Atlas"
    })

# ================== USERS ==================
@app.route("/api/users", methods=["GET"])
def get_users():
    users = [serialize(u) for u in db.users.find()]
    return jsonify({"success": True, "users": users})

@app.route("/api/users", methods=["POST"])
def add_user():
    data = request.json
    db.users.insert_one({
        "name": data.get("name"),
        "email": data.get("email"),
        "role": data.get("role"),
        "created_at": datetime.datetime.utcnow()
    })
    return jsonify({"success": True})

@app.route("/api/users/<id>", methods=["DELETE"])
def delete_user(id):
    db.users.delete_one({"_id": ObjectId(id)})
    return jsonify({"success": True})

# ================== UPLOADS ==================
@app.route("/api/uploads", methods=["GET"])
def get_uploads():
    uploads = [serialize(u) for u in db.uploads.find()]
    return jsonify({"success": True, "uploads": uploads})

@app.route("/api/uploads", methods=["POST"])
def add_upload():
    data = request.json
    db.uploads.insert_one({
        "name": data.get("name"),
        "status": "Pending",
        "created_at": datetime.datetime.utcnow()
    })
    return jsonify({"success": True})

@app.route("/api/uploads/<id>/approve", methods=["POST"])
def approve_upload(id):
    db.uploads.update_one(
        {"_id": ObjectId(id)},
        {"$set": {"status": "Approved"}}
    )
    return jsonify({"success": True})

@app.route("/api/uploads/<id>/reject", methods=["POST"])
def reject_upload(id):
    db.uploads.update_one(
        {"_id": ObjectId(id)},
        {"$set": {"status": "Rejected"}}
    )
    return jsonify({"success": True})

# ================== FAQ ==================
@app.route("/api/faqs", methods=["GET"])
def get_faqs():
    faqs = [serialize(f) for f in db.faqs.find()]
    return jsonify({"success": True, "faqs": faqs})

@app.route("/api/faqs", methods=["POST"])
def add_faq():
    data = request.json
    db.faqs.insert_one({
        "question": data.get("question"),
        "created_at": datetime.datetime.utcnow()
    })
    return jsonify({"success": True})

# ================== AI CONTENT ==================
@app.route("/api/ai-content", methods=["GET"])
def get_ai_content():
    content = [serialize(c) for c in db.ai_content.find()]
    return jsonify({"success": True, "ai_content": content})

@app.route("/api/ai-content", methods=["POST"])
def add_ai_content():
    data = request.json
    db.ai_content.insert_one({
        "title": data.get("title"),
        "content": data.get("content"),
        "created_at": datetime.datetime.utcnow()
    })
    return jsonify({"success": True})

# ================== ALERTS ==================
@app.route("/api/alerts", methods=["GET"])
def get_alerts():
    alerts = [serialize(a) for a in db.alerts.find()]
    return jsonify({"success": True, "alerts": alerts})

@app.route("/api/alerts", methods=["POST"])
def add_alert():
    data = request.json
    db.alerts.insert_one({
        "message": data.get("message"),
        "type": data.get("type"),
        "created_at": datetime.datetime.utcnow()
    })
    return jsonify({"success": True})

# ================== REPORTS ==================
@app.route("/api/reports", methods=["GET"])
def get_reports():
    reports = [serialize(r) for r in db.reports.find()]
    return jsonify({"success": True, "reports": reports})

@app.route("/api/reports", methods=["POST"])
def add_report():
    data = request.json
    db.reports.insert_one({
        "title": data.get("title"),
        "content": data.get("content"),
        "created_at": datetime.datetime.utcnow()
    })
    return jsonify({"success": True})

# ================== DASHBOARD ==================
@app.route("/api/dashboard/stats", methods=["GET"])
def dashboard_stats():
    return jsonify({
        "success": True,
        "stats": {
            "total_users": db.users.count_documents({}),
            "total_uploads": db.uploads.count_documents({}),
            "pending_uploads": db.uploads.count_documents({"status": "Pending"}),
            "approved_uploads": db.uploads.count_documents({"status": "Approved"}),
            "rejected_uploads": db.uploads.count_documents({"status": "Rejected"}),
        }
    })

# ================== RUN ==================
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=PORT, debug=False)
