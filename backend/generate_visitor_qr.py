import qrcode
from PIL import Image
import base64
from io import BytesIO
import hashlib
import time

def generate_gate_qr():
    \"\"\"Generate static gate QR for registration page.\"\"\"
    url = "https://srimcaai.web.app/register"
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    qr.add_data(url)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white")
    img.save("assets/images/visitor_qr.png")
    print(f"Generated static GATE QR saved to assets/images/visitor_qr.png -> {url}")
    return "assets/images/visitor_qr.png"

def generate_dynamic_qr(visitor_id: str, frontend_url: str = "https://srimcaai.web.app"):
    \"\"\"Generate dynamic visitor pass QR (used by API).\"\"\"
    # Token: vid + ts + secret[:16]
    secret = "srimca-secret-key-123"  # Use config.JWT_SECRET_KEY in prod
    payload = f"{visitor_id}:{int(time.time())}:{secret}"
    token = hashlib.sha256(payload.encode()).hexdigest()[:8]
    
    qr_url = f"{frontend_url}/checkin?vid={visitor_id}&token={token}"
    
    qr = qrcode.QRCode(
        version=2,
        error_correction=qrcode.constants.ERROR_CORRECT_H,
        box_size=8,
        border=4,
    )
    qr.add_data(qr_url)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white")
    
    # Base64 for API response
    buffer = BytesIO()
    img.save(buffer, format='PNG')
    img_str = base64.b64encode(buffer.getvalue()).decode()
    
    return {
        'qr_url': qr_url,
        'qr_base64': f'data:image/png;base64,{img_str}',
        'token': token
    }

if __name__ == "__main__":
    # Generate static gate QR (for college entrance)
    generate_gate_qr()
    
    # Example dynamic QR
    print("\nExample dynamic QR for visitor_id='test123':")
    dynamic = generate_dynamic_qr("test123")
    print(f"QR URL: {dynamic['qr_url']}")
    print(f"Token: {dynamic['token']}")
    print("Use /api/visitor/qr/<id> in API for real generation.")
