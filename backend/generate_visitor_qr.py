"""
SRIMCA AI - Visitor Gate QR Code Generator
Generates high-resolution static & dynamic QR codes for visitor check-in & welcome screen.
"""

import os
import time
import base64
from io import BytesIO
import qrcode
from PIL import Image

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))
ASSETS_IMG_DIR = os.path.join(PROJECT_ROOT, "assets", "images")
DYNAMIC_QR_DIR = os.path.join(ASSETS_IMG_DIR, "dynamic_qr")

# Production & Local URLs
DEFAULT_VISITOR_URL = os.getenv("VISITOR_GATE_URL", "https://srimcaai.web.app/#/visitor-welcome")
LOCAL_VISITOR_URL = "http://localhost:8080/#/visitor-welcome"


def generate_gate_qr(target_url=DEFAULT_VISITOR_URL, output_filename="visitor_qr.png"):
    """
    Generate Static Gate QR code that visitors scan on campus.
    Directs visitor to the Welcome Screen with Get Started / Register / Login options.
    """
    os.makedirs(ASSETS_IMG_DIR, exist_ok=True)
    out_path = os.path.join(ASSETS_IMG_DIR, output_filename)

    qr = qrcode.QRCode(
        version=2,
        error_correction=qrcode.constants.ERROR_CORRECT_H,
        box_size=12,
        border=4,
    )
    qr.add_data(target_url)
    qr.make(fit=True)

    img = qr.make_image(fill_color="#001F3F", back_color="white").convert("RGBA")

    # Save QR image
    img.save(out_path)
    print(f"[SUCCESS] Static Gate QR generated at: {out_path}")
    print(f"[INFO] Target URL: {target_url}")
    return out_path


def generate_dynamic_qr(visitor_token=None):
    """
    Generate dynamic QR pass for an individual registered visitor.
    """
    if not visitor_token:
        visitor_token = f"visitor_{int(time.time())}"

    os.makedirs(DYNAMIC_QR_DIR, exist_ok=True)
    qr_data = f"https://srimcaai.web.app/#/visitor-pass?token={visitor_token}"

    qr = qrcode.QRCode(
        version=2,
        error_correction=qrcode.constants.ERROR_CORRECT_M,
        box_size=10,
        border=4,
    )
    qr.add_data(qr_data)
    qr.make(fit=True)

    img = qr.make_image(fill_color="#001F3F", back_color="white")
    timestamp = int(time.time())
    file_path = os.path.join(DYNAMIC_QR_DIR, f"pass_{visitor_token}_{timestamp}.png")
    img.save(file_path)

    # Base64 string for direct mobile/web API transport
    buffered = BytesIO()
    img.save(buffered, format="PNG")
    img_b64 = base64.b64encode(buffered.getvalue()).decode("utf-8")

    print(f"[SUCCESS] Dynamic Visitor QR Pass generated: {file_path}")
    print(f"[INFO] Token: {visitor_token}")
    return {
        "token": visitor_token,
        "qr_data": qr_data,
        "file_path": file_path,
        "base64": f"data:image/png;base64,{img_b64}"
    }


if __name__ == "__main__":
    print("--- SRIMCA AI QR Code Generator ---")
    gate_qr = generate_gate_qr()
    sample_dynamic = generate_dynamic_qr("sample_guest_01")
    print("--- Completed Successfully ---")
