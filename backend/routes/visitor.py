from flask import Blueprint, request, jsonify
from datetime import datetime
import jwt
from database import get_database, Collections
from functools import wraps
from urllib.parse import urlparse, parse_qs

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
    db = get_database()
    user = db[Collections.USERS].find_one({"_id": visitor_id}, {"password": 0})
    return jsonify(user or {"error": "User not found"})

# 📌 UPDATE PROFILE
@visitor_bp.route('/profile/<visitor_id>', methods=['PATCH'])
@token_required
def update_profile(visitor_id):
    data = request.json
    db = get_database()
    result = db[Collections.USERS].update_one({"_id": visitor_id}, {"$set": data})
    return jsonify({"message": "Profile updated", "modified": result.modified_count > 0})

# 📌 VISITOR HISTORY
@visitor_bp.route('/history/<visitor_id>', methods=['GET'])
@token_required
def get_history(visitor_id):
    db = get_database()
    logs = list(db[Collections.VISITOR_LOGS].find({"visitor_id": visitor_id}).sort("check_in", -1))
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
    return jsonify({"qr_data": token, "qr": qr_data})

# 📌 CHECK-IN (QR SCAN)
@visitor_bp.route('/checkin', methods=['GET'])
def checkin():
    token = request.args.get("token")
    if not token:
        return jsonify({"error": "Token missing"}), 400

    try:
        data = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
        visitor_id = data["visitor_id"]
        db = get_database()
        log = {
            "visitor_id": visitor_id,
            "check_in": datetime.utcnow(),
            "status": "checked_in"
        }
        db[Collections.VISITOR_LOGS].insert_one(log)
        return jsonify({"success": True, "message": "Check-in successful"})
    except:
        return jsonify({"error": "Invalid QR"}), 400

# 📌 QR CHECK-IN (POST)
@visitor_bp.route('/qr/checkin', methods=['POST'])
def qr_checkin():
    data = request.json
    qr_code = data.get('qr_code')
    if not qr_code:
        return jsonify({"success": False, "message": "QR code missing"}), 400

    try:
        if qr_code.startswith('http'):
            parsed = urlparse(qr_code)
            token = parse_qs(parsed.query).get('token', [None])[0]
        else:
            token = qr_code

        if not token:
            return jsonify({"success": False, "message": "Invalid QR code"}), 400

        payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
        visitor_id = payload["visitor_id"]
        db = get_database()
        log = {
            "visitor_id": visitor_id,
            "check_in": datetime.utcnow(),
            "status": "checked_in"
        }
        db[Collections.VISITOR_LOGS].insert_one(log)
        return jsonify({"success": True, "message": "Check-in successful"})
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 400

# 📌 GATE QR LANDING
@visitor_bp.route('/visitor', methods=['GET'])
def visitor_entry():
    html = '''
<!DOCTYPE html>
<html>
<head>
    <title>SRIMCA AI - Redirecting...</title>
    <meta http-equiv="refresh" content="0; url=https://srimcaai.web.app/#/">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; background: #001F3F; color: white; }
        .logo { font-size: 48px; font-weight: bold; margin-bottom: 20px; }
    </style>
</head>
<body>
    <div class="logo">SRIMCA AI</div>
    <h1>Welcome Visitor!</h1>
    <p>Redirecting to app...</p>
    <a href="https://srimcaai.web.app/#/">Open SRIMCA AI App</a>
    <script>window.location.href = 'https://srimcaai.web.app/#/';</script>
</body>
</html>
    '''
    return html, 200, {'Content-Type': 'text/html; charset=utf-8'}


