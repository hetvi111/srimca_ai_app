import os
import sys

# Add backend directory to sys.path so app.py and internal modules can be imported
backend_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'backend')
if backend_path not in sys.path:
    sys.path.insert(0, backend_path)

from app import app
