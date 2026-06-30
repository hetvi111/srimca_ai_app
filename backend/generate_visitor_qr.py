import qrcode
from PIL import Image
import base64
from io import BytesIO
import hashlib
import time
import os

# 🔹 1. Generate Static Gate QR (for general visitor entry)
def generate_gate_qr():
    url = "https://srimcaai.web.app/#/"  # Direct to Flutter web app landing

    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )

    qr.add_data(url)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white")

    # Save to Flutter assets folder
    os.makedirs("../../assets/images", exist_ok=True)
    path = "../../assets/images/visitor_qr.png"
    img.save(path)

    print(f"✅ Static GATE QR saved at: {path}")
    print(f"👉 URL: {url}")

    return path

# 🔹 2. Generate Dynamic QR for specific visitor (token-based)
def generate_dynamic_qr(visitor_token):
    """
    Generate QR for specific visitor check-in.
    Token example: visitor_<id>_<timestamp>
    """
    # Create secure token if none provided
    if visitor_token is None or visitor_token == "test123":
        visitor_token = f"visitor_test_{int(time.time())}"
    
    # QR data: backend endpoint with token param
    qr_data = f"https://srimcaai.web.app/#/qr/{visitor_token}"  # Web app QR route
    
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )

    qr.add_data(qr_data)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white")
    
    # Save dynamic QR
    os.makedirs("../../assets/images/dynamic_qr", exist_ok=True)
    timestamp = int(time.time())
    path = f"../../assets/images/dynamic_qr/visitor_{visitor_token}_{timestamp}.png"
    img.save(path)
    
    # Base64 for immediate use (Flutter/API)
    buffered = BytesIO()
    img.save(buffered, format="PNG")
    img_str = base64.b64encode(buffered.getvalue()).decode()

    print(f"✅ Dynamic QR saved at: {path}")
    print(f"👉 QR URL: {qr_data}")
    print(f"👉 Token: {visitor_token}")

    return {
        "qr_url": qr_data,
        "token": visitor_token,
        "image_path": path,
        "base64": f"data:image/png;base64,{img_str}"
    }

# 🔹 Main Run
if __name__ == "__main__":
    # Generate static gate QR
    generate_gate_qr()

    # Example dynamic QR
    print("\n🔹 Example Dynamic QR:")
    dynamic = generate_dynamic_qr("test123")
    print(f"QR URL: {dynamic['qr_url']}")
    print(f"Token: {dynamic['token']}")
    print("✅ Script completed successfully!")
