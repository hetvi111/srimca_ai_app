from flask import Blueprint, request, jsonify
from datetime import datetime
import jwt
import qrcode
import base64
from io import BytesIO
from database import mongo
from functools import wraps

visitor_bp = Blueprint('visitor', __name__)

JWT_SECRET = "your_secret_key"


# 🔐 JWT Decorator
def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get("Authorization")
        if not token:
            return jsonify({"error": "Token missing"}), 401

        try:
            token = token.split(" ")[1]
            data = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            request.user = data
        except:
            return jsonify({"error": "Invalid token"}), 401

        return f(*args, **kwargs)
    return decorated


# 📌 GET PROFILE
@visitor_bp.route('/profile/<visitor_id>', methods=['GET'])
@token_required
def get_profile(visitor_id):
    user = mongo.db.users.find_one({"_id": visitor_id}, {"password": 0})
    return jsonify(user)


# 📌 UPDATE PROFILE
@visitor_bp.route('/profile/<visitor_id>', methods=['PATCH'])
@token_required
def update_profile(visitor_id):
    data = request.json
    mongo.db.users.update_one({"_id": visitor_id}, {"$set": data})
    return jsonify({"message": "Profile updated"})


# 📌 VISITOR HISTORY
@visitor_bp.route('/history/<visitor_id>', methods=['GET'])
@token_required
def get_history(visitor_id):
    logs = list(mongo.db.visitor_logs.find({"visitor_id": visitor_id}))
    for log in logs:
        log["_id"] = str(log["_id"])
    return jsonify(logs)


# 📌 GENERATE QR (DYNAMIC)
@visitor_bp.route('/qr/<visitor_id>', methods=['GET'])
@token_required
def generate_qr(visitor_id):

    payload = {
        "visitor_id": visitor_id,
        "ts": int(datetime.utcnow().timestamp())
    }

    token = jwt.encode(payload, JWT_SECRET, algorithm="HS256")

    qr_data = f"http://localhost:5000/api/visitor/checkin?token={token}"

    # Return token string for client-side QR generation
    return jsonify({"qr_data": token, "qr": qr_data})


# 📌 CHECK-IN (QR SCAN)
@visitor_bp.route('/checkin', methods=['GET'])
def checkin():
    token = request.args.get("token")

    try:
        data = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
        visitor_id = data["visitor_id"]

        log = {
            "visitor_id": visitor_id,
            "check_in": datetime.utcnow(),
            "status": "checked_in"
        }

        mongo.db.visitor_logs.insert_one(log)

        return jsonify({"message": "Check-in successful"})
    except:
        return jsonify({"error": "Invalid QR"}), 400


# 📌 QR CHECK-IN (POST)
@visitor_bp.route('/qr/checkin', methods=['POST'])
def qr_checkin():
    data = request.json
    qr_code = data.get('qr_code')

    try:
        if qr_code.startswith('http://'):
            from urllib.parse import urlparse, parse_qs
            parsed = urlparse(qr_code)
            token = parse_qs(parsed.query).get('token', [None])[0]
        else:
            token = qr_code

        if not token:
            return jsonify({"success": False, "message": "Invalid QR code"}), 400

        payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
        visitor_id = payload["visitor_id"]

        log = {
            "visitor_id": visitor_id,
            "check_in": datetime.utcnow(),
            "status": "checked_in"
        }

        mongo.db.visitor_logs.insert_one(log)

        return jsonify({"success": True, "message": "Check-in successful"})
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 400