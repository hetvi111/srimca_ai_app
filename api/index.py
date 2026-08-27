import os
import sys

# Ensure root and backend directories are in sys.path for Vercel Serverless Functions
root_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
backend_path = os.path.join(root_dir, 'backend')

if root_dir not in sys.path:
    sys.path.insert(0, root_dir)
if backend_path not in sys.path:
    sys.path.insert(0, backend_path)

from app import app
