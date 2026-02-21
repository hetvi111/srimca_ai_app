"""
Routes package initialization
"""

from flask import Blueprint

# Import all route blueprints
from .notices import notices_bp
from .assignments import assignments_bp
from .materials import materials_bp
from .faqs import faqs_bp

__all__ = ['notices_bp', 'assignments_bp', 'materials_bp', 'faqs_bp']
