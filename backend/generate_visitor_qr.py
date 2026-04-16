import qrcode
from PIL import Image

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
print(f"Generated visitor QR code saved to assets/images/visitor_qr.png pointing to {url}")
