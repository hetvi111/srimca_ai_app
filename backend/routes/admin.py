"""
Admin routes for SRIMCA AI Backend
Comprehensive Administration Blueprint covering the Seven Modules:
1. Dashboard Overview & Statistics
2. Campus Navigation Management
3. AI Knowledge Base Management & Unresolved Queries
4. Notices & Notifications Management
5. User Management & Access Control
6. Visitor Pass Approval & Secure Gate Passes
7. Reports & Audit Activity Logs (with CSV Export)
"""

import io
import csv
import re
import secrets
from datetime import datetime, timedelta
from functools import wraps
from flask import Blueprint, request, jsonify, Response
from bson import ObjectId
import bcrypt
import jwt

from database import get_collection, get_database, Collections
from models import (
    UserModel,
    NoticeModel,
    CampusLocationModel,
    KnowledgeBaseModel,
    ActivityLogModel,
    UnresolvedQueryModel,
)
from auth import verify_jwt_token
from config import get_config
from notification_helper import create_notification

admin_bp = Blueprint('admin', __name__, url_prefix='/api/admin')


# ---------------------------------------------------------------------------
# Auth Helper & Decorator
# ---------------------------------------------------------------------------

def require_admin(f):
    """Decorator to require valid admin JWT authentication"""
    @wraps(f)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get('Authorization')
        if not auth_header:
            return jsonify({'error': 'No authorization header provided'}), 401
        
        parts = auth_header.split()
        if len(parts) != 2 or parts[0].lower() != 'bearer':
            return jsonify({'error': 'Invalid authorization header format'}), 401
        
        payload = verify_jwt_token(parts[1])
        if payload is None:
            return jsonify({'error': 'Invalid or expired authentication token'}), 401
        
        if payload.get('role') != 'admin':
            return jsonify({'error': 'Admin authorization required for this action'}), 403
        
        request.user = payload
        return f(*args, **kwargs)
    return decorated


def log_admin_activity(action: str, module: str, affected_record: str = '', details: str = '', outcome: str = 'success'):
    """Log an administrative action into the audit trail"""
    try:
        acting_user = 'Admin'
        user_id = ''
        if hasattr(request, 'user') and request.user:
            acting_user = request.user.get('email') or request.user.get('name') or 'Admin'
            user_id = str(request.user.get('user_id', ''))
        
        logs_col = get_collection(Collections.ACTIVITY_LOGS)
        logs_col.insert_one(ActivityLogModel.create_log(
            acting_user=acting_user,
            action=action,
            module=module,
            affected_record=str(affected_record)[:150],
            details=str(details)[:300],
            user_id=user_id,
            outcome=outcome
        ))
    except Exception as e:
        print(f"[ActivityLog Warning] Could not record activity: {e}")


# ---------------------------------------------------------------------------
# Authentication
# ---------------------------------------------------------------------------

@admin_bp.route('/login', methods=['POST'], endpoint='admin_login')
def admin_login():
    """Admin login endpoint returning JWT token with admin role"""
    try:
        data = request.get_json() or {}
        email = (data.get('email') or '').strip().lower()
        password = data.get('password') or ''
        
        if not email or not password:
            return jsonify({'error': 'Email and password are required'}), 400
        
        users_col = get_collection(Collections.USERS)
        user = users_col.find_one({'email': email, 'role': 'admin'})
        
        if not user:
            return jsonify({'error': 'Invalid admin credentials'}), 401
        
        if not user.get('is_active', True):
            return jsonify({'error': 'Admin account is deactivated'}), 401
        
        stored_password = user.get('password', '')
        if isinstance(stored_password, str):
            stored_password = stored_password.encode('utf-8')
        
        try:
            if not bcrypt.checkpw(password.encode('utf-8'), stored_password):
                return jsonify({'error': 'Invalid admin credentials'}), 401
        except Exception:
            return jsonify({'error': 'Invalid admin credentials'}), 401
        
        config = get_config()
        payload = {
            'user_id': str(user.get('_id')),
            'email': user.get('email'),
            'role': 'admin',
            'name': user.get('name'),
            'exp': datetime.utcnow() + timedelta(hours=config.JWT_EXPIRATION_HOURS),
            'iat': datetime.utcnow()
        }
        
        token = jwt.encode(payload, config.JWT_SECRET_KEY, algorithm='HS256')
        
        # Update last login
        users_col.update_one({'_id': user['_id']}, {'$set': {'last_login': datetime.utcnow()}})
        
        log_admin_activity(
            action='LOGIN',
            module='Auth',
            affected_record=email,
            details='Admin logged in successfully'
        )
        
        return jsonify({
            'success': True,
            'token': token,
            'admin': {
                '_id': str(user.get('_id')),
                'name': user.get('name'),
                'email': user.get('email'),
                'role': 'admin'
            }
        }), 200
    
    except Exception as e:
        print(f"Admin login error: {e}")
        return jsonify({'error': 'Admin login failed'}), 500


# ---------------------------------------------------------------------------
# MODULE 1: Dashboard Overview & Live Statistics
# ---------------------------------------------------------------------------

@admin_bp.route('/dashboard/stats', methods=['GET'], endpoint='get_dashboard_live_stats')
@require_admin
def get_dashboard_live_stats():
    """Retrieve comprehensive live statistics directly from MongoDB collections"""
    try:
        users_col = get_collection(Collections.USERS)
        visitors_col = get_collection(Collections.VISITORS)
        locations_col = get_collection(Collections.CAMPUS_LOCATIONS)
        knowledge_col = get_collection(Collections.KNOWLEDGE_BASE)
        notices_col = get_collection(Collections.NOTICES)
        queries_col = get_collection(Collections.AI_QUERIES)
        logs_col = get_collection(Collections.ACTIVITY_LOGS)
        unresolved_col = get_collection(Collections.UNRESOLVED_QUERIES)

        # 1. User counts
        total_users = users_col.count_documents({})
        total_students = users_col.count_documents({'role': 'student'})
        total_faculty = users_col.count_documents({'role': 'faculty'})
        total_admins = users_col.count_documents({'role': 'admin'})
        total_visitor_users = users_col.count_documents({'role': 'visitor'})
        active_users = users_col.count_documents({'is_active': True})

        # 2. Campus locations
        total_locations = locations_col.count_documents({})
        verified_locations = locations_col.count_documents({'coordinates_verified': True})

        # 3. Knowledge base
        total_knowledge = knowledge_col.count_documents({})
        unresolved_questions = unresolved_col.count_documents({'status': 'pending'})

        # 4. Notices
        total_notices = notices_col.count_documents({})
        published_notices = notices_col.count_documents({'is_active': True, 'status': {'$ne': 'draft'}})
        draft_notices = notices_col.count_documents({'status': 'draft'})

        # 5. Visitor passes (merged count from visitors and visitor users)
        pending_passes = visitors_col.count_documents({'status': 'pending'}) + users_col.count_documents({'role': 'visitor', 'approval_status': 'pending'})
        approved_passes = visitors_col.count_documents({'status': 'approved'}) + users_col.count_documents({'role': 'visitor', 'approval_status': 'approved'})
        rejected_passes = visitors_col.count_documents({'status': 'rejected'}) + users_col.count_documents({'role': 'visitor', 'approval_status': 'rejected'})
        total_visitors = max(total_visitor_users, visitors_col.count_documents({}))

        # 6. Recent activities
        recent_logs_cursor = logs_col.find().sort('created_at', -1).limit(8)
        recent_activities = [ActivityLogModel.to_dict(l) for l in recent_logs_cursor]

        # 7. Recent notices
        recent_notices_cursor = notices_col.find().sort('created_at', -1).limit(5)
        recent_notices = [NoticeModel.to_dict(n) for n in recent_notices_cursor]

        # 8. Monthly registration trend (last 6 months)
        now = datetime.utcnow()
        monthly_registrations = []
        for offset in range(5, -1, -1):
            m = now.month - offset
            y = now.year
            while m <= 0:
                m += 12
                y -= 1
            start = datetime(y, m, 1)
            next_m = m + 1
            next_y = y
            if next_m > 12:
                next_m = 1
                next_y += 1
            end = datetime(next_y, next_m, 1)
            count = users_col.count_documents({'created_at': {'$gte': start, '$lt': end}})
            monthly_registrations.append({
                'month': start.strftime('%b'),
                'year': y,
                'count': count
            })

        return jsonify({
            'success': True,
            'stats': {
                'users': {
                    'total': total_users,
                    'students': total_students,
                    'faculty': total_faculty,
                    'visitors': total_visitors,
                    'admins': total_admins,
                    'active': active_users
                },
                'locations': {
                    'total': total_locations,
                    'verified': verified_locations
                },
                'knowledge': {
                    'total': total_knowledge,
                    'unresolved_questions': unresolved_questions
                },
                'notices': {
                    'total': total_notices,
                    'published': published_notices,
                    'draft': draft_notices
                },
                'visitor_passes': {
                    'total': total_visitors,
                    'pending': pending_passes,
                    'approved': approved_passes,
                    'rejected': rejected_passes
                },
                'recent_activities': recent_activities,
                'recent_notices': recent_notices,
                'charts': {
                    'monthly_registrations': monthly_registrations,
                    'role_distribution': {
                        'students': total_students,
                        'faculty': total_faculty,
                        'visitors': total_visitors,
                        'admins': total_admins
                    }
                }
            }
        }), 200

    except Exception as e:
        print(f"Dashboard live stats error: {e}")
        return jsonify({'error': 'Failed to retrieve dashboard stats', 'details': str(e)}), 500


# Backward compatibility for existing /stats endpoint
@admin_bp.route('/stats', methods=['GET'], endpoint='get_stats')
def get_stats():
    """Admin dashboard statistics (backward compatibility)"""
    try:
        users_col = get_collection(Collections.USERS)
        visitors_col = get_collection(Collections.VISITORS)
        notices_col = get_collection(Collections.NOTICES)
        materials_col = get_collection(Collections.MATERIALS)
        queries_col = get_collection(Collections.QUERIES)

        return jsonify({
            'stats': {
                'total_students': users_col.count_documents({'role': 'student'}),
                'total_faculty': users_col.count_documents({'role': 'faculty'}),
                'total_admin': users_col.count_documents({'role': 'admin'}),
                'total_users': users_col.count_documents({}),
                'total_visitors': visitors_col.count_documents({}),
                'total_notices': notices_col.count_documents({}),
                'total_materials': materials_col.count_documents({}),
                'total_queries': queries_col.count_documents({}),
                'active_users': users_col.count_documents({'is_active': True})
            }
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ---------------------------------------------------------------------------
# MODULE 2: Campus Navigation Management
# ---------------------------------------------------------------------------

@admin_bp.route('/campus-locations', methods=['GET'], endpoint='get_campus_locations')
@require_admin
def get_campus_locations():
    """Retrieve all campus locations with optional search and filters"""
    try:
        search = (request.args.get('search') or '').strip().lower()
        category = (request.args.get('category') or '').strip().lower()
        verified_filter = request.args.get('verified')

        col = get_collection(Collections.CAMPUS_LOCATIONS)
        query = {}

        if category and category != 'all':
            query['category'] = category

        if verified_filter is not None and verified_filter != 'all':
            query['coordinates_verified'] = (verified_filter.lower() == 'true')

        if search:
            query['$or'] = [
                {'name': {'$regex': re.escape(search), '$options': 'i'}},
                {'description': {'$regex': re.escape(search), '$options': 'i'}},
                {'building': {'$regex': re.escape(search), '$options': 'i'}},
                {'aliases': {'$regex': re.escape(search), '$options': 'i'}},
            ]

        docs = list(col.find(query).sort('name', 1))
        locations = [CampusLocationModel.to_dict(d) for d in docs]

        return jsonify({
            'success': True,
            'count': len(locations),
            'locations': locations
        }), 200

    except Exception as e:
        print(f"Get campus locations error: {e}")
        return jsonify({'error': 'Failed to fetch campus locations'}), 500


@admin_bp.route('/campus-locations', methods=['POST'], endpoint='create_campus_location')
@require_admin
def create_campus_location():
    """Add a new verified or unverified campus location"""
    try:
        data = request.get_json() or {}
        name = (data.get('name') or '').strip()
        if not name:
            return jsonify({'error': 'Location name is required'}), 400

        col = get_collection(Collections.CAMPUS_LOCATIONS)
        
        # Check duplicate
        if col.find_one({'name': {'$regex': f"^{re.escape(name)}$", '$options': 'i'}}):
            return jsonify({'error': f"Location '{name}' already exists"}), 400

        # Validate coordinates
        try:
            latitude = float(data.get('latitude', 0.0) or 0.0)
            longitude = float(data.get('longitude', 0.0) or 0.0)
        except (ValueError, TypeError):
            return jsonify({'error': 'Invalid latitude or longitude format'}), 400

        if not (-90.0 <= latitude <= 90.0) or not (-180.0 <= longitude <= 180.0):
            return jsonify({'error': 'Coordinates out of valid geographical bounds'}), 400

        # Parse aliases
        raw_aliases = data.get('aliases', [])
        if isinstance(raw_aliases, str):
            aliases = [a.strip().lower() for a in raw_aliases.split(',') if a.strip()]
        else:
            aliases = [str(a).strip().lower() for a in raw_aliases if str(a).strip()]

        # Ensure name itself is included in aliases
        if name.lower() not in aliases:
            aliases.append(name.lower())

        coordinates_verified = bool(data.get('coordinates_verified', False))
        # Coordinates cannot be verified if they are zero
        if latitude == 0.0 or longitude == 0.0:
            coordinates_verified = False

        location_doc = CampusLocationModel.create_location(
            name=name,
            latitude=latitude,
            longitude=longitude,
            description=data.get('description', ''),
            aliases=aliases,
            building=data.get('building', ''),
            floor=data.get('floor', ''),
            room=data.get('room', ''),
            category=data.get('category', 'academic').lower(),
            coordinates_verified=coordinates_verified
        )

        # Optional route details
        if data.get('routes'):
            location_doc['routes'] = data.get('routes')

        result = col.insert_one(location_doc)
        location_doc['_id'] = result.inserted_id

        log_admin_activity(
            action='CREATE',
            module='Campus Navigation',
            affected_record=name,
            details=f"Added campus location '{name}' ({data.get('category', 'academic')})"
        )

        return jsonify({
            'success': True,
            'message': 'Campus location added successfully',
            'location': CampusLocationModel.to_dict(location_doc)
        }), 201

    except Exception as e:
        print(f"Create campus location error: {e}")
        return jsonify({'error': 'Failed to create campus location', 'details': str(e)}), 500


@admin_bp.route('/campus-locations/<location_id>', methods=['GET'], endpoint='get_campus_location')
@require_admin
def get_campus_location(location_id):
    """Get single campus location by ID"""
    try:
        col = get_collection(Collections.CAMPUS_LOCATIONS)
        doc = col.find_one({'_id': ObjectId(location_id)})
        if not doc:
            return jsonify({'error': 'Campus location not found'}), 404
        return jsonify({'success': True, 'location': CampusLocationModel.to_dict(doc)}), 200
    except Exception as e:
        return jsonify({'error': 'Invalid location ID or query error'}), 500


@admin_bp.route('/campus-locations/<location_id>', methods=['PUT'], endpoint='update_campus_location')
@require_admin
def update_campus_location(location_id):
    """Update existing campus location"""
    try:
        data = request.get_json() or {}
        col = get_collection(Collections.CAMPUS_LOCATIONS)
        existing = col.find_one({'_id': ObjectId(location_id)})
        if not existing:
            return jsonify({'error': 'Campus location not found'}), 404

        update_fields = {'updated_at': datetime.utcnow()}

        if 'name' in data and data['name'].strip():
            update_fields['name'] = data['name'].strip()

        if 'description' in data:
            update_fields['description'] = str(data['description']).strip()

        if 'building' in data:
            update_fields['building'] = str(data['building']).strip()

        if 'floor' in data:
            update_fields['floor'] = str(data['floor']).strip()

        if 'room' in data:
            update_fields['room'] = str(data['room']).strip()

        if 'category' in data:
            update_fields['category'] = str(data['category']).strip().lower()

        if 'latitude' in data or 'longitude' in data:
            lat = float(data.get('latitude', existing.get('latitude', 0.0)) or 0.0)
            lon = float(data.get('longitude', existing.get('longitude', 0.0)) or 0.0)
            if not (-90.0 <= lat <= 90.0) or not (-180.0 <= lon <= 180.0):
                return jsonify({'error': 'Coordinates out of bounds'}), 400
            update_fields['latitude'] = lat
            update_fields['longitude'] = lon

        if 'coordinates_verified' in data:
            verified = bool(data['coordinates_verified'])
            if update_fields.get('latitude', existing.get('latitude')) == 0.0:
                verified = False
            update_fields['coordinates_verified'] = verified

        if 'aliases' in data:
            raw = data['aliases']
            if isinstance(raw, str):
                aliases = [a.strip().lower() for a in raw.split(',') if a.strip()]
            else:
                aliases = [str(a).strip().lower() for a in raw if str(a).strip()]
            update_fields['aliases'] = aliases

        if 'routes' in data:
            update_fields['routes'] = data['routes']

        col.update_one({'_id': ObjectId(location_id)}, {'$set': update_fields})
        updated = col.find_one({'_id': ObjectId(location_id)})

        log_admin_activity(
            action='UPDATE',
            module='Campus Navigation',
            affected_record=updated.get('name', ''),
            details=f"Updated campus location '{updated.get('name')}'"
        )

        return jsonify({
            'success': True,
            'message': 'Location updated successfully',
            'location': CampusLocationModel.to_dict(updated)
        }), 200

    except Exception as e:
        print(f"Update location error: {e}")
        return jsonify({'error': 'Failed to update campus location'}), 500


@admin_bp.route('/campus-locations/<location_id>', methods=['DELETE'], endpoint='delete_campus_location')
@require_admin
def delete_campus_location(location_id):
    """Delete a campus location"""
    try:
        col = get_collection(Collections.CAMPUS_LOCATIONS)
        existing = col.find_one({'_id': ObjectId(location_id)})
        if not existing:
            return jsonify({'error': 'Location not found'}), 404

        name = existing.get('name', 'Location')
        col.delete_one({'_id': ObjectId(location_id)})

        log_admin_activity(
            action='DELETE',
            module='Campus Navigation',
            affected_record=name,
            details=f"Deleted campus location '{name}'"
        )

        return jsonify({'success': True, 'message': f"Location '{name}' deleted successfully"}), 200

    except Exception as e:
        print(f"Delete location error: {e}")
        return jsonify({'error': 'Failed to delete campus location'}), 500


# ---------------------------------------------------------------------------
# MODULE 3: AI Knowledge Base & Unresolved Questions
# ---------------------------------------------------------------------------

@admin_bp.route('/knowledge', methods=['GET'], endpoint='get_knowledge_entries')
@require_admin
def get_knowledge_entries():
    """Retrieve all official college knowledge base entries with search & filters"""
    try:
        search = (request.args.get('search') or '').strip()
        category = (request.args.get('category') or '').strip().lower()
        status = (request.args.get('status') or '').strip().lower()

        col = get_collection(Collections.KNOWLEDGE_BASE)
        query = {}

        if category and category != 'all':
            query['category'] = category

        if status and status != 'all':
            query['status'] = status

        if search:
            query['$or'] = [
                {'title': {'$regex': re.escape(search), '$options': 'i'}},
                {'text': {'$regex': re.escape(search), '$options': 'i'}},
                {'tags': {'$regex': re.escape(search), '$options': 'i'}},
                {'question': {'$regex': re.escape(search), '$options': 'i'}},
                {'answer': {'$regex': re.escape(search), '$options': 'i'}},
            ]

        docs = list(col.find(query).sort('created_at', -1))
        entries = [KnowledgeBaseModel.to_dict(d) for d in docs]

        return jsonify({
            'success': True,
            'count': len(entries),
            'entries': entries
        }), 200

    except Exception as e:
        print(f"Get knowledge entries error: {e}")
        return jsonify({'error': 'Failed to fetch knowledge base entries'}), 500


@admin_bp.route('/knowledge', methods=['POST'], endpoint='create_knowledge_entry')
@require_admin
def create_knowledge_entry():
    """Add a new official knowledge base entry for AI Chat retrieval"""
    try:
        data = request.get_json() or {}
        title = (data.get('title') or data.get('question') or '').strip()
        text = (data.get('text') or data.get('answer') or '').strip()
        category = (data.get('category') or 'general').strip().lower()

        if not title or not text:
            return jsonify({'error': 'Title/Question and Content/Answer are required'}), 400

        raw_tags = data.get('tags', [])
        if isinstance(raw_tags, str):
            tags = [t.strip().lower() for t in raw_tags.split(',') if t.strip()]
        else:
            tags = [str(t).strip().lower() for t in raw_tags if str(t).strip()]

        col = get_collection(Collections.KNOWLEDGE_BASE)
        creator_email = request.user.get('email', 'admin')

        entry_doc = KnowledgeBaseModel.create_entry(
            title=title,
            text=text,
            category=category,
            tags=tags,
            status=data.get('status', 'approved'),
            created_by=creator_email
        )

        result = col.insert_one(entry_doc)
        entry_doc['_id'] = result.inserted_id

        log_admin_activity(
            action='CREATE',
            module='AI Knowledge Base',
            affected_record=title,
            details=f"Created official knowledge entry '{title}' under {category}"
        )

        return jsonify({
            'success': True,
            'message': 'Official knowledge base entry created successfully',
            'entry': KnowledgeBaseModel.to_dict(entry_doc)
        }), 201

    except Exception as e:
        print(f"Create knowledge entry error: {e}")
        return jsonify({'error': 'Failed to create knowledge entry'}), 500


@admin_bp.route('/knowledge/<entry_id>', methods=['GET'], endpoint='get_knowledge_entry')
@require_admin
def get_knowledge_entry(entry_id):
    """Get single knowledge base entry"""
    try:
        col = get_collection(Collections.KNOWLEDGE_BASE)
        doc = col.find_one({'_id': ObjectId(entry_id)})
        if not doc:
            return jsonify({'error': 'Knowledge base entry not found'}), 404
        return jsonify({'success': True, 'entry': KnowledgeBaseModel.to_dict(doc)}), 200
    except Exception as e:
        return jsonify({'error': 'Invalid entry ID'}), 500


@admin_bp.route('/knowledge/<entry_id>', methods=['PUT'], endpoint='update_knowledge_entry')
@require_admin
def update_knowledge_entry(entry_id):
    """Update official knowledge base entry"""
    try:
        data = request.get_json() or {}
        col = get_collection(Collections.KNOWLEDGE_BASE)
        existing = col.find_one({'_id': ObjectId(entry_id)})
        if not existing:
            return jsonify({'error': 'Knowledge base entry not found'}), 404

        update_fields = {'updated_at': datetime.utcnow()}

        if 'title' in data and data['title'].strip():
            update_fields['title'] = data['title'].strip()

        if 'text' in data and data['text'].strip():
            update_fields['text'] = data['text'].strip()

        if 'category' in data:
            update_fields['category'] = data['category'].strip().lower()

        if 'status' in data:
            update_fields['status'] = data['status'].strip().lower()

        if 'tags' in data:
            raw = data['tags']
            if isinstance(raw, str):
                update_fields['tags'] = [t.strip().lower() for t in raw.split(',') if t.strip()]
            else:
                update_fields['tags'] = [str(t).strip().lower() for t in raw if str(t).strip()]

        col.update_one({'_id': ObjectId(entry_id)}, {'$set': update_fields})
        updated = col.find_one({'_id': ObjectId(entry_id)})

        log_admin_activity(
            action='UPDATE',
            module='AI Knowledge Base',
            affected_record=updated.get('title', ''),
            details=f"Updated knowledge entry '{updated.get('title')}'"
        )

        return jsonify({
            'success': True,
            'message': 'Knowledge base entry updated successfully',
            'entry': KnowledgeBaseModel.to_dict(updated)
        }), 200

    except Exception as e:
        print(f"Update knowledge error: {e}")
        return jsonify({'error': 'Failed to update knowledge base entry'}), 500


@admin_bp.route('/knowledge/<entry_id>', methods=['DELETE'], endpoint='delete_knowledge_entry')
@require_admin
def delete_knowledge_entry(entry_id):
    """Delete a knowledge base entry"""
    try:
        col = get_collection(Collections.KNOWLEDGE_BASE)
        existing = col.find_one({'_id': ObjectId(entry_id)})
        if not existing:
            return jsonify({'error': 'Knowledge base entry not found'}), 404

        title = existing.get('title', 'Entry')
        col.delete_one({'_id': ObjectId(entry_id)})

        log_admin_activity(
            action='DELETE',
            module='AI Knowledge Base',
            affected_record=title,
            details=f"Deleted knowledge entry '{title}'"
        )

        return jsonify({'success': True, 'message': 'Entry deleted successfully'}), 200

    except Exception as e:
        print(f"Delete knowledge error: {e}")
        return jsonify({'error': 'Failed to delete knowledge base entry'}), 500


@admin_bp.route('/knowledge/unresolved', methods=['GET'], endpoint='get_unresolved_queries')
@require_admin
def get_unresolved_queries():
    """Retrieve unanswered or unresolved user questions for review"""
    try:
        status_filter = (request.args.get('status') or 'pending').strip().lower()
        col = get_collection(Collections.UNRESOLVED_QUERIES)

        query = {}
        if status_filter != 'all':
            query['status'] = status_filter

        docs = list(col.find(query).sort('created_at', -1).limit(100))
        result = [UnresolvedQueryModel.to_dict(d) for d in docs]

        return jsonify({
            'success': True,
            'count': len(result),
            'queries': result
        }), 200

    except Exception as e:
        print(f"Get unresolved queries error: {e}")
        return jsonify({'error': 'Failed to retrieve unresolved queries'}), 500


@admin_bp.route('/knowledge/resolve-query', methods=['POST'], endpoint='resolve_unresolved_query')
@require_admin
def resolve_unresolved_query():
    """Convert an unresolved user question into an approved knowledge-base entry and mark resolved"""
    try:
        data = request.get_json() or {}
        query_id = data.get('query_id')
        approved_answer = (data.get('approved_answer') or '').strip()
        category = (data.get('category') or 'faqs').strip().lower()
        title = (data.get('title') or '').strip()

        if not query_id or not approved_answer:
            return jsonify({'error': 'query_id and approved_answer are required'}), 400

        unres_col = get_collection(Collections.UNRESOLVED_QUERIES)
        q_doc = unres_col.find_one({'_id': ObjectId(query_id)})
        if not q_doc:
            return jsonify({'error': 'Unresolved query record not found'}), 404

        question_text = q_doc.get('question', '')
        if not title:
            title = question_text

        # 1. Add to knowledge base
        kb_col = get_collection(Collections.KNOWLEDGE_BASE)
        admin_email = request.user.get('email', 'admin')

        entry_doc = KnowledgeBaseModel.create_entry(
            title=title,
            text=approved_answer,
            category=category,
            tags=[w for w in question_text.lower().split() if len(w) > 3],
            status='approved',
            created_by=admin_email
        )
        kb_res = kb_col.insert_one(entry_doc)

        # 2. Update unresolved query record
        unres_col.update_one(
            {'_id': ObjectId(query_id)},
            {'$set': {
                'status': 'resolved',
                'approved_answer': approved_answer,
                'resolved_by': admin_email,
                'resolved_at': datetime.utcnow()
            }}
        )

        log_admin_activity(
            action='RESOLVE',
            module='AI Knowledge Base',
            affected_record=title,
            details=f"Resolved question '{question_text}' and created knowledge entry"
        )

        return jsonify({
            'success': True,
            'message': 'Official answer approved and added to knowledge base',
            'knowledge_entry_id': str(kb_res.inserted_id)
        }), 200

    except Exception as e:
        print(f"Resolve query error: {e}")
        return jsonify({'error': 'Failed to resolve query'}), 500


# ---------------------------------------------------------------------------
# MODULE 4: Notices & Notifications
# ---------------------------------------------------------------------------

@admin_bp.route('/notices', methods=['GET'], endpoint='get_admin_notices')
@require_admin
def get_admin_notices():
    """Get all notices (including draft/published/archived) with filtering"""
    try:
        search = (request.args.get('search') or '').strip()
        status_filter = (request.args.get('status') or '').strip().lower()
        category_filter = (request.args.get('category') or '').strip().lower()
        target_role = (request.args.get('target_role') or '').strip().lower()

        col = get_collection(Collections.NOTICES)
        query = {}

        if status_filter and status_filter != 'all':
            if status_filter == 'draft':
                query['status'] = 'draft'
            elif status_filter == 'published':
                query['$or'] = [{'status': 'published'}, {'status': {'$exists': False}, 'is_active': True}]
            elif status_filter == 'inactive':
                query['is_active'] = False

        if category_filter and category_filter != 'all':
            query['category'] = category_filter

        if target_role and target_role != 'all':
            query['target_role'] = target_role

        if search:
            query['$or'] = [
                {'title': {'$regex': re.escape(search), '$options': 'i'}},
                {'content': {'$regex': re.escape(search), '$options': 'i'}}
            ]

        docs = list(col.find(query).sort('created_at', -1))
        notices = []
        for d in docs:
            nd = NoticeModel.to_dict(d)
            nd['status'] = d.get('status', 'published' if d.get('is_active', True) else 'inactive')
            nd['category'] = d.get('category', 'notice')
            nd['target_role'] = d.get('target_role', 'all')
            nd['expiry_date'] = d.get('expiry_date')
            notices.append(nd)

        return jsonify({
            'success': True,
            'count': len(notices),
            'notices': notices
        }), 200

    except Exception as e:
        print(f"Get admin notices error: {e}")
        return jsonify({'error': 'Failed to fetch notices'}), 500


@admin_bp.route('/notices', methods=['POST'], endpoint='create_admin_notice')
@require_admin
def create_admin_notice():
    """Create a new notice with draft/published status and push notification dispatch"""
    try:
        data = request.get_json() or {}
        title = (data.get('title') or '').strip()
        content = (data.get('content') or '').strip()
        category = (data.get('category') or 'notice').strip().lower()
        target_role = (data.get('target_role') or 'all').strip().lower()
        priority = (data.get('priority') or 'normal').strip().lower()
        status = (data.get('status') or 'published').strip().lower()
        expiry_date = data.get('expiry_date')

        if not title or not content:
            return jsonify({'error': 'Title and content are required'}), 400

        sender_id = request.user.get('user_id', '')
        admin_email = request.user.get('email', 'Admin')

        notice_doc = {
            'title': title,
            'content': content,
            'category': category,
            'target_role': target_role,
            'target_courses': data.get('target_courses', []),
            'target_semesters': data.get('target_semesters', []),
            'priority': priority,
            'status': status,
            'is_active': (status != 'draft'),
            'expiry_date': expiry_date,
            'faculty_id': sender_id,
            'author_name': admin_email,
            'views': 0,
            'created_at': datetime.utcnow(),
            'updated_at': datetime.utcnow()
        }

        col = get_collection(Collections.NOTICES)
        result = col.insert_one(notice_doc)
        notice_id_str = str(result.inserted_id)

        # If published immediately, dispatch to notifications system
        if status == 'published':
            try:
                prefix = {'exam': 'Exam: ', 'event': 'Event: ', 'announcement': 'Important: '}.get(category, 'Notice: ')
                create_notification(
                    title=f"{prefix}{title}",
                    message=content[:140],
                    notification_type=category if category in ['exam', 'event'] else 'notice',
                    target_role=target_role,
                    target_courses=data.get('target_courses', []),
                    target_semesters=data.get('target_semesters', []),
                    priority='high' if priority == 'urgent' else 'medium',
                    sender_role='admin',
                    sender_id=sender_id,
                    sender_name=admin_email,
                    related_id=notice_id_str,
                    related_type='notice'
                )
            except Exception as notif_err:
                print(f"[Admin Notice] Notification dispatch warning: {notif_err}")

        log_admin_activity(
            action='PUBLISH' if status == 'published' else 'DRAFT',
            module='Notices & Notifications',
            affected_record=title,
            details=f"Created {status} notice '{title}' for target {target_role}"
        )

        return jsonify({
            'success': True,
            'message': f"Notice {'published' if status == 'published' else 'saved as draft'} successfully",
            'notice_id': notice_id_str
        }), 201

    except Exception as e:
        print(f"Create admin notice error: {e}")
        return jsonify({'error': 'Failed to create notice'}), 500


@admin_bp.route('/notices/<notice_id>', methods=['PUT'], endpoint='update_admin_notice')
@require_admin
def update_admin_notice(notice_id):
    """Update or publish a notice"""
    try:
        data = request.get_json() or {}
        col = get_collection(Collections.NOTICES)
        existing = col.find_one({'_id': ObjectId(notice_id)})
        if not existing:
            return jsonify({'error': 'Notice not found'}), 404

        update_fields = {'updated_at': datetime.utcnow()}

        if 'title' in data and data['title'].strip():
            update_fields['title'] = data['title'].strip()
        if 'content' in data and data['content'].strip():
            update_fields['content'] = data['content'].strip()
        if 'category' in data:
            update_fields['category'] = data['category'].strip().lower()
        if 'target_role' in data:
            update_fields['target_role'] = data['target_role'].strip().lower()
        if 'priority' in data:
            update_fields['priority'] = data['priority'].strip().lower()
        if 'expiry_date' in data:
            update_fields['expiry_date'] = data['expiry_date']
        if 'is_active' in data:
            update_fields['is_active'] = bool(data['is_active'])

        was_draft = existing.get('status') == 'draft'
        new_status = data.get('status')
        if new_status:
            update_fields['status'] = new_status
            update_fields['is_active'] = (new_status != 'draft')

        col.update_one({'_id': ObjectId(notice_id)}, {'$set': update_fields})

        # If transitioning from draft to published, send notification
        if was_draft and new_status == 'published':
            try:
                title = update_fields.get('title', existing.get('title', 'Notice'))
                content = update_fields.get('content', existing.get('content', ''))
                create_notification(
                    title=f"Notice: {title}",
                    message=content[:140],
                    notification_type='notice',
                    target_role=update_fields.get('target_role', existing.get('target_role', 'all')),
                    sender_role='admin',
                    sender_id=request.user.get('user_id', ''),
                    related_id=str(notice_id),
                    related_type='notice'
                )
            except Exception as ne:
                print(f"Notice publish alert error: {ne}")

        log_admin_activity(
            action='UPDATE',
            module='Notices & Notifications',
            affected_record=existing.get('title', ''),
            details=f"Updated notice '{existing.get('title')}' (Status: {update_fields.get('status', existing.get('status'))})"
        )

        return jsonify({'success': True, 'message': 'Notice updated successfully'}), 200

    except Exception as e:
        print(f"Update notice error: {e}")
        return jsonify({'error': 'Failed to update notice'}), 500


@admin_bp.route('/notices/<notice_id>', methods=['DELETE'], endpoint='delete_admin_notice')
@require_admin
def delete_admin_notice(notice_id):
    """Delete a notice"""
    try:
        col = get_collection(Collections.NOTICES)
        existing = col.find_one({'_id': ObjectId(notice_id)})
        if not existing:
            return jsonify({'error': 'Notice not found'}), 404

        title = existing.get('title', 'Notice')
        col.delete_one({'_id': ObjectId(notice_id)})

        log_admin_activity(
            action='DELETE',
            module='Notices & Notifications',
            affected_record=title,
            details=f"Deleted notice '{title}'"
        )

        return jsonify({'success': True, 'message': f"Notice '{title}' deleted successfully"}), 200

    except Exception as e:
        print(f"Delete notice error: {e}")
        return jsonify({'error': 'Failed to delete notice'}), 500


@admin_bp.route('/notifications/stats', methods=['GET'], endpoint='get_admin_notification_stats')
@require_admin
def get_admin_notification_stats():
    """Retrieve notification delivery and read status metrics"""
    try:
        col = get_collection(Collections.NOTIFICATIONS)
        total = col.count_documents({})
        read_count = col.count_documents({'is_read': True})
        unread_count = col.count_documents({'is_read': False})

        by_role = {
            'all': col.count_documents({'target_role': 'all'}),
            'student': col.count_documents({'target_role': 'student'}),
            'faculty': col.count_documents({'target_role': 'faculty'}),
            'visitor': col.count_documents({'target_role': 'visitor'})
        }

        return jsonify({
            'success': True,
            'stats': {
                'total_notifications': total,
                'read_count': read_count,
                'unread_count': unread_count,
                'delivery_rate': f"{round((read_count / total * 100) if total > 0 else 0, 1)}%",
                'target_distribution': by_role
            }
        }), 200

    except Exception as e:
        return jsonify({'error': 'Failed to fetch notification metrics'}), 500


# ---------------------------------------------------------------------------
# MODULE 5: User Management & Access Control
# ---------------------------------------------------------------------------

@admin_bp.route('/users', methods=['GET'], endpoint='get_admin_users')
@require_admin
def get_admin_users():
    """View registered users with role and status filtering, searching, and pagination"""
    try:
        search = (request.args.get('search') or '').strip().lower()
        role = (request.args.get('role') or '').strip().lower()
        status = (request.args.get('status') or '').strip().lower()
        limit = min(int(request.args.get('limit', 100)), 500)
        offset = int(request.args.get('offset', 0))

        col = get_collection(Collections.USERS)
        query = {}

        if role and role != 'all':
            query['role'] = role

        if status and status != 'all':
            if status == 'active':
                query['is_active'] = True
            elif status == 'inactive':
                query['is_active'] = False

        if search:
            query['$or'] = [
                {'name': {'$regex': re.escape(search), '$options': 'i'}},
                {'email': {'$regex': re.escape(search), '$options': 'i'}},
                {'mobile': {'$regex': re.escape(search), '$options': 'i'}},
                {'enrollment': {'$regex': re.escape(search), '$options': 'i'}},
                {'department': {'$regex': re.escape(search), '$options': 'i'}}
            ]

        total_matching = col.count_documents(query)
        cursor = col.find(query).sort('created_at', -1).skip(offset).limit(limit)

        users = []
        for u in cursor:
            # Safely strip out passwords and hashes
            u_dict = UserModel.to_dict(u)
            u_dict.pop('password', None)
            u_dict.pop('otp_hash', None)
            users.append(u_dict)

        return jsonify({
            'success': True,
            'total': total_matching,
            'count': len(users),
            'users': users
        }), 200

    except Exception as e:
        print(f"Get admin users error: {e}")
        return jsonify({'error': 'Failed to retrieve users'}), 500


@admin_bp.route('/users', methods=['POST'], endpoint='create_admin_user')
@require_admin
def create_admin_user():
    """Create a new user account with secure password hashing and role validation"""
    try:
        data = request.get_json() or {}
        name = (data.get('name') or '').strip()
        email = (data.get('email') or '').strip().lower()
        password = data.get('password') or ''
        role = (data.get('role') or 'student').strip().lower()

        if not name or not email or not password:
            return jsonify({'error': 'Name, email, and password are required'}), 400

        permitted_roles = {'student', 'faculty', 'visitor', 'admin'}
        if role not in permitted_roles:
            return jsonify({'error': f"Role must be one of: {', '.join(permitted_roles)}"}), 400

        col = get_collection(Collections.USERS)
        if col.find_one({'email': email}):
            return jsonify({'error': f"User with email '{email}' already exists"}), 400

        # Bcrypt password hashing
        hashed_pw = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

        user_doc = UserModel.create_user(
            name=name,
            email=email,
            password=hashed_pw,
            role=role
        )
        user_doc['mobile'] = str(data.get('mobile', data.get('phone', ''))).strip()
        user_doc['is_active'] = True

        # Role specific fields
        profile = data.get('profile', {})
        if role == 'student':
            user_doc['department'] = data.get('department', profile.get('department', ''))
            user_doc['semester'] = data.get('semester', profile.get('semester', ''))
            user_doc['enrollment'] = data.get('enrollment', data.get('enrollment_number', ''))
        elif role == 'faculty':
            user_doc['department'] = data.get('department', profile.get('department', ''))
            user_doc['designation'] = data.get('designation', profile.get('designation', ''))
        elif role == 'visitor':
            user_doc['purpose'] = data.get('purpose', '')
            user_doc['approval_status'] = 'approved'

        user_doc['profile'] = profile

        result = col.insert_one(user_doc)
        user_doc['_id'] = result.inserted_id

        log_admin_activity(
            action='CREATE',
            module='User Management',
            affected_record=email,
            details=f"Created new {role} account for '{name}' ({email})"
        )

        safe_user = UserModel.to_dict(user_doc)
        safe_user.pop('password', None)

        return jsonify({
            'success': True,
            'message': f"Account for {name} ({role}) created successfully",
            'user': safe_user
        }), 201

    except Exception as e:
        print(f"Create user error: {e}")
        return jsonify({'error': 'Failed to create user account'}), 500


@admin_bp.route('/users/<user_id>', methods=['GET'], endpoint='get_admin_user_detail')
@require_admin
def get_admin_user_detail(user_id):
    """Get detailed profile for a specific user"""
    try:
        col = get_collection(Collections.USERS)
        u = col.find_one({'_id': ObjectId(user_id)})
        if not u:
            return jsonify({'error': 'User not found'}), 404

        safe_u = UserModel.to_dict(u)
        safe_u.pop('password', None)
        return jsonify({'success': True, 'user': safe_u}), 200

    except Exception as e:
        return jsonify({'error': 'Invalid user ID'}), 500


@admin_bp.route('/users/<user_id>', methods=['PUT'], endpoint='update_admin_user')
@require_admin
def update_admin_user(user_id):
    """Update user account details and permissions"""
    try:
        data = request.get_json() or {}
        col = get_collection(Collections.USERS)
        target_user = col.find_one({'_id': ObjectId(user_id)})
        if not target_user:
            return jsonify({'error': 'User not found'}), 404

        update_fields = {'updated_at': datetime.utcnow()}

        if 'name' in data and data['name'].strip():
            update_fields['name'] = data['name'].strip()

        if 'email' in data and data['email'].strip():
            new_email = data['email'].strip().lower()
            if new_email != target_user.get('email'):
                if col.find_one({'email': new_email, '_id': {'$ne': ObjectId(user_id)}}):
                    return jsonify({'error': 'Email is already used by another account'}), 400
                update_fields['email'] = new_email

        if 'mobile' in data:
            update_fields['mobile'] = str(data['mobile']).strip()

        if 'role' in data:
            new_role = data['role'].strip().lower()
            permitted_roles = {'student', 'faculty', 'visitor', 'admin'}
            if new_role not in permitted_roles:
                return jsonify({'error': 'Invalid role specified'}), 400
            
            # Prevent demoting the only admin
            if target_user.get('role') == 'admin' and new_role != 'admin':
                admin_count = col.count_documents({'role': 'admin', 'is_active': True})
                if admin_count <= 1:
                    return jsonify({'error': 'Cannot change role: system requires at least one active admin'}), 400
            update_fields['role'] = new_role

        if 'is_active' in data:
            new_active = bool(data['is_active'])
            if not new_active and target_user.get('role') == 'admin':
                admin_count = col.count_documents({'role': 'admin', 'is_active': True})
                if admin_count <= 1:
                    return jsonify({'error': 'Cannot deactivate the sole remaining admin account'}), 400
            update_fields['is_active'] = new_active

        # Optional password reset by admin
        if data.get('password'):
            new_pw = str(data['password']).strip()
            if len(new_pw) >= 6:
                hashed = bcrypt.hashpw(new_pw.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
                update_fields['password'] = hashed

        # Profile / Role specific updates
        if 'profile' in data:
            update_fields['profile'] = data['profile']
        if 'department' in data:
            update_fields['department'] = str(data['department']).strip()
        if 'semester' in data:
            update_fields['semester'] = str(data['semester']).strip()
        if 'enrollment' in data:
            update_fields['enrollment'] = str(data['enrollment']).strip()

        col.update_one({'_id': ObjectId(user_id)}, {'$set': update_fields})
        updated = col.find_one({'_id': ObjectId(user_id)})

        log_admin_activity(
            action='UPDATE',
            module='User Management',
            affected_record=target_user.get('email', ''),
            details=f"Updated account info for '{target_user.get('email')}'"
        )

        safe_u = UserModel.to_dict(updated)
        safe_u.pop('password', None)

        return jsonify({'success': True, 'message': 'User updated successfully', 'user': safe_u}), 200

    except Exception as e:
        print(f"Update user error: {e}")
        return jsonify({'error': 'Failed to update user'}), 500


@admin_bp.route('/users/<user_id>/toggle-status', methods=['POST'], endpoint='toggle_user_status')
@require_admin
def toggle_user_status(user_id):
    """Toggle user active / inactive account status"""
    try:
        col = get_collection(Collections.USERS)
        target_user = col.find_one({'_id': ObjectId(user_id)})
        if not target_user:
            return jsonify({'error': 'User not found'}), 404

        current_status = target_user.get('is_active', True)
        new_status = not current_status

        if not new_status and target_user.get('role') == 'admin':
            admin_count = col.count_documents({'role': 'admin', 'is_active': True})
            if admin_count <= 1:
                return jsonify({'error': 'Cannot deactivate the last active administrator'}), 400

        col.update_one({'_id': ObjectId(user_id)}, {'$set': {'is_active': new_status, 'updated_at': datetime.utcnow()}})

        log_admin_activity(
            action='DEACTIVATE' if not new_status else 'ACTIVATE',
            module='User Management',
            affected_record=target_user.get('email', ''),
            details=f"{'Activated' if new_status else 'Deactivated'} account for '{target_user.get('email')}'"
        )

        return jsonify({
            'success': True,
            'is_active': new_status,
            'message': f"Account {'activated' if new_status else 'deactivated'} successfully"
        }), 200

    except Exception as e:
        return jsonify({'error': 'Failed to change account status'}), 500


@admin_bp.route('/users/<user_id>', methods=['DELETE'], endpoint='delete_admin_user_account')
@require_admin
def delete_admin_user_account(user_id):
    """Safely delete a user account"""
    try:
        col = get_collection(Collections.USERS)
        target_user = col.find_one({'_id': ObjectId(user_id)})
        if not target_user:
            return jsonify({'error': 'User not found'}), 404

        if target_user.get('role') == 'admin':
            admin_count = col.count_documents({'role': 'admin'})
            if admin_count <= 1:
                return jsonify({'error': 'Cannot delete the sole administrator account'}), 400

        email = target_user.get('email', '')
        col.delete_one({'_id': ObjectId(user_id)})

        log_admin_activity(
            action='DELETE',
            module='User Management',
            affected_record=email,
            details=f"Deleted user account '{email}'"
        )

        return jsonify({'success': True, 'message': f"User account '{email}' deleted successfully"}), 200

    except Exception as e:
        return jsonify({'error': 'Failed to delete user'}), 500


# ---------------------------------------------------------------------------
# MODULE 6: Visitor Pass Approval & Secure QR Verification
# ---------------------------------------------------------------------------

@admin_bp.route('/visitor-passes', methods=['GET'], endpoint='get_visitor_passes')
@require_admin
def get_visitor_passes():
    """Retrieve visitor pass applications from both visitors collection and visitor accounts"""
    try:
        status_filter = (request.args.get('status') or 'all').strip().lower()
        search = (request.args.get('search') or '').strip().lower()

        visitors_col = get_collection(Collections.VISITORS)
        users_col = get_collection(Collections.USERS)

        visitor_docs = list(visitors_col.find().sort('created_at', -1))
        visitor_users = list(users_col.find({'role': 'visitor'}).sort('created_at', -1))

        merged = {}
        for v in visitor_docs:
            vid = str(v.get('_id', ''))
            st = (v.get('status') or 'pending').lower()
            merged[vid] = {
                '_id': vid,
                'source': 'visitors',
                'name': v.get('name') or 'Visitor',
                'email': v.get('email', ''),
                'phone': v.get('phone', ''),
                'purpose': v.get('purpose', ''),
                'visit_date': v.get('visit_date', ''),
                'status': st,
                'pass_token': v.get('pass_token', ''),
                'approval_remarks': v.get('approval_remarks', ''),
                'created_at': v.get('created_at').isoformat() if v.get('created_at') else None
            }

        # Merge user registered visitors
        for u in visitor_users:
            uid = str(u.get('_id', ''))
            email = u.get('email', '')
            st = (u.get('approval_status') or u.get('status') or 'pending').lower()
            
            # If already added via visitors collection with same email, update fields
            already_exists = False
            for vid, item in merged.items():
                if email and item.get('email', '').lower() == email.lower():
                    already_exists = True
                    break
            
            if not already_exists:
                merged[uid] = {
                    '_id': uid,
                    'source': 'users',
                    'name': u.get('name') or 'Visitor',
                    'email': email,
                    'phone': u.get('mobile', ''),
                    'purpose': u.get('purpose', ''),
                    'visit_date': u.get('visit_date', ''),
                    'status': st,
                    'pass_token': u.get('pass_token', ''),
                    'approval_remarks': u.get('approval_remarks', ''),
                    'created_at': u.get('created_at').isoformat() if u.get('created_at') else None
                }

        passes = list(merged.values())

        # Filter by status
        if status_filter != 'all':
            passes = [p for p in passes if p['status'] == status_filter]

        # Filter by search
        if search:
            passes = [p for p in passes if (
                search in p['name'].lower() or
                search in p['email'].lower() or
                search in p['phone'].lower() or
                search in p['purpose'].lower()
            )]

        # Sort descending by creation date
        passes.sort(key=lambda x: x.get('created_at') or '', reverse=True)

        return jsonify({
            'success': True,
            'count': len(passes),
            'passes': passes
        }), 200

    except Exception as e:
        print(f"Get visitor passes error: {e}")
        return jsonify({'error': 'Failed to retrieve visitor pass applications'}), 500


@admin_bp.route('/visitor-passes/<pass_id>/approve', methods=['POST'], endpoint='approve_visitor_pass')
@require_admin
def approve_visitor_pass(pass_id):
    """Approve a visitor pass application and issue a secure verification token"""
    try:
        data = request.get_json() or {}
        remarks = (data.get('remarks') or '').strip()
        valid_until = data.get('valid_until') or (datetime.utcnow() + timedelta(days=1)).strftime('%Y-%m-%d')

        visitors_col = get_collection(Collections.VISITORS)
        users_col = get_collection(Collections.USERS)

        # Generate cryptographically secure pass token for QR code
        # Private visitor details are NOT exposed inside the raw QR text
        pass_token = secrets.token_hex(16)

        update_payload = {
            'status': 'approved',
            'pass_token': pass_token,
            'approval_remarks': remarks,
            'valid_until': valid_until,
            'approved_at': datetime.utcnow(),
            'approved_by': request.user.get('email', 'admin')
        }

        res_v = visitors_col.update_one({'_id': ObjectId(pass_id)}, {'$set': update_payload})
        res_u = users_col.update_one(
            {'_id': ObjectId(pass_id), 'role': 'visitor'},
            {'$set': {
                'approval_status': 'approved',
                'pass_token': pass_token,
                'approval_remarks': remarks,
                'valid_until': valid_until
            }}
        )

        if res_v.matched_count == 0 and res_u.matched_count == 0:
            return jsonify({'error': 'Visitor record not found'}), 404

        # Fetch visitor name for activity log
        visitor_name = 'Visitor'
        doc = visitors_col.find_one({'_id': ObjectId(pass_id)}) or users_col.find_one({'_id': ObjectId(pass_id)})
        if doc:
            visitor_name = doc.get('name', 'Visitor')

        log_admin_activity(
            action='APPROVE',
            module='Visitor Pass Approval',
            affected_record=visitor_name,
            details=f"Approved visitor pass for '{visitor_name}' (Token: {pass_token[:8]}...)"
        )

        # Construct verification URL
        verification_url = f"https://srimcaai.web.app/#/visitor-pass?token={pass_token}"

        return jsonify({
            'success': True,
            'message': f"Visitor pass for {visitor_name} approved successfully",
            'pass_token': pass_token,
            'verification_url': verification_url
        }), 200

    except Exception as e:
        print(f"Approve visitor pass error: {e}")
        return jsonify({'error': 'Failed to approve visitor pass'}), 500


@admin_bp.route('/visitor-passes/<pass_id>/reject', methods=['POST'], endpoint='reject_visitor_pass')
@require_admin
def reject_visitor_pass(pass_id):
    """Reject a visitor pass application with an optional reason"""
    try:
        data = request.get_json() or {}
        reason = (data.get('reason') or data.get('rejection_reason') or 'Application rejected by administration').strip()

        visitors_col = get_collection(Collections.VISITORS)
        users_col = get_collection(Collections.USERS)

        update_payload = {
            'status': 'rejected',
            'rejection_reason': reason,
            'rejected_at': datetime.utcnow(),
            'rejected_by': request.user.get('email', 'admin')
        }

        res_v = visitors_col.update_one({'_id': ObjectId(pass_id)}, {'$set': update_payload})
        res_u = users_col.update_one(
            {'_id': ObjectId(pass_id), 'role': 'visitor'},
            {'$set': {'approval_status': 'rejected', 'rejection_reason': reason}}
        )

        if res_v.matched_count == 0 and res_u.matched_count == 0:
            return jsonify({'error': 'Visitor record not found'}), 404

        visitor_name = 'Visitor'
        doc = visitors_col.find_one({'_id': ObjectId(pass_id)}) or users_col.find_one({'_id': ObjectId(pass_id)})
        if doc:
            visitor_name = doc.get('name', 'Visitor')

        log_admin_activity(
            action='REJECT',
            module='Visitor Pass Approval',
            affected_record=visitor_name,
            details=f"Rejected visitor pass for '{visitor_name}'. Reason: {reason}"
        )

        return jsonify({
            'success': True,
            'message': f"Visitor pass application for {visitor_name} rejected",
            'reason': reason
        }), 200

    except Exception as e:
        print(f"Reject visitor pass error: {e}")
        return jsonify({'error': 'Failed to reject visitor pass'}), 500


# Backward compatibility for existing /visitors endpoints
@admin_bp.route('/visitors', methods=['GET'], endpoint='get_visitors')
def get_visitors():
    """Get all visitors (backward compatibility)"""
    return get_visitor_passes()


@admin_bp.route('/visitors/<visitor_id>', methods=['PUT'], endpoint='update_visitor')
def update_visitor(visitor_id):
    """Update visitor status (backward compatibility)"""
    try:
        data = request.get_json() or {}
        status = data.get('status', 'pending')
        if status == 'approved':
            return approve_visitor_pass(visitor_id)
        elif status == 'rejected':
            return reject_visitor_pass(visitor_id)

        visitors_col = get_collection(Collections.VISITORS)
        users_col = get_collection(Collections.USERS)
        visitors_col.update_one({'_id': ObjectId(visitor_id)}, {'$set': {'status': status}})
        users_col.update_one({'_id': ObjectId(visitor_id), 'role': 'visitor'}, {'$set': {'approval_status': status}})
        return jsonify({'message': 'Visitor updated successfully'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ---------------------------------------------------------------------------
# MODULE 7: Reports & Activity Logs (with CSV Export)
# ---------------------------------------------------------------------------

@admin_bp.route('/reports/summary', methods=['GET'], endpoint='get_reports_summary')
@require_admin
def get_reports_summary():
    """Generate detailed audit and module reports with date filters"""
    try:
        timeframe = request.args.get('timeframe', '30days').lower()
        now = datetime.utcnow()
        if timeframe == '7days':
            start_date = now - timedelta(days=7)
        elif timeframe == '30days':
            start_date = now - timedelta(days=30)
        else:
            start_date = datetime(2020, 1, 1)

        users_col = get_collection(Collections.USERS)
        locations_col = get_collection(Collections.CAMPUS_LOCATIONS)
        knowledge_col = get_collection(Collections.KNOWLEDGE_BASE)
        notices_col = get_collection(Collections.NOTICES)
        visitors_col = get_collection(Collections.VISITORS)
        queries_col = get_collection(Collections.AI_QUERIES)
        unres_col = get_collection(Collections.UNRESOLVED_QUERIES)
        logs_col = get_collection(Collections.ACTIVITY_LOGS)

        # 1. User registration report
        user_reg_period = users_col.count_documents({'created_at': {'$gte': start_date}})
        total_students = users_col.count_documents({'role': 'student'})
        total_faculty = users_col.count_documents({'role': 'faculty'})
        total_visitors = users_col.count_documents({'role': 'visitor'})
        total_admins = users_col.count_documents({'role': 'admin'})

        # 2. Campus locations breakdown
        loc_categories = {}
        for cat in ['academic', 'administrative', 'amenity', 'sports', 'other']:
            loc_categories[cat] = locations_col.count_documents({'category': cat})
        verified_locs = locations_col.count_documents({'coordinates_verified': True})
        unverified_locs = locations_col.count_documents({'coordinates_verified': False})

        # 3. Knowledge base reports
        kb_categories = {}
        for cat in ['departments', 'courses', 'faculty', 'facilities', 'rules', 'faqs', 'admissions', 'general']:
            kb_categories[cat] = knowledge_col.count_documents({'category': cat})
        resolved_count = unres_col.count_documents({'status': 'resolved'})
        pending_count = unres_col.count_documents({'status': 'pending'})

        # 4. Notice and announcement reports
        notices_period = notices_col.count_documents({'created_at': {'$gte': start_date}})
        published_count = notices_col.count_documents({'status': 'published'})

        # 5. Visitor pass reports
        v_approved = visitors_col.count_documents({'status': 'approved'}) + users_col.count_documents({'role': 'visitor', 'approval_status': 'approved'})
        v_pending = visitors_col.count_documents({'status': 'pending'}) + users_col.count_documents({'role': 'visitor', 'approval_status': 'pending'})
        v_rejected = visitors_col.count_documents({'status': 'rejected'}) + users_col.count_documents({'role': 'visitor', 'approval_status': 'rejected'})

        # 6. AI chat queries reports
        total_ai_queries = queries_col.count_documents({})
        queries_in_period = queries_col.count_documents({'created_at': {'$gte': start_date}})

        return jsonify({
            'success': True,
            'timeframe': timeframe,
            'reports': {
                'users': {
                    'registered_in_period': user_reg_period,
                    'students': total_students,
                    'faculty': total_faculty,
                    'visitors': total_visitors,
                    'admins': total_admins
                },
                'locations': {
                    'total': locations_col.count_documents({}),
                    'verified': verified_locs,
                    'unverified': unverified_locs,
                    'by_category': loc_categories
                },
                'knowledge_base': {
                    'total_entries': knowledge_col.count_documents({}),
                    'by_category': kb_categories,
                    'resolved_questions': resolved_count,
                    'pending_questions': pending_count
                },
                'notices': {
                    'created_in_period': notices_period,
                    'total_published': published_count
                },
                'visitor_passes': {
                    'approved': v_approved,
                    'pending': v_pending,
                    'rejected': v_rejected
                },
                'ai_chat': {
                    'total_queries': total_ai_queries,
                    'queries_in_period': queries_in_period
                }
            }
        }), 200

    except Exception as e:
        print(f"Reports summary error: {e}")
        return jsonify({'error': 'Failed to generate reports'}), 500


@admin_bp.route('/activity-logs', methods=['GET'], endpoint='get_admin_activity_logs')
@require_admin
def get_admin_activity_logs():
    """Retrieve audit activity logs with date range and module filtering"""
    try:
        module = (request.args.get('module') or 'all').strip()
        action = (request.args.get('action') or 'all').strip().upper()
        search = (request.args.get('search') or '').strip().lower()
        limit = min(int(request.args.get('limit', 100)), 500)
        offset = int(request.args.get('offset', 0))

        col = get_collection(Collections.ACTIVITY_LOGS)
        query = {}

        if module != 'all':
            query['module'] = module

        if action != 'ALL':
            query['action'] = action

        if search:
            query['$or'] = [
                {'acting_user': {'$regex': re.escape(search), '$options': 'i'}},
                {'affected_record': {'$regex': re.escape(search), '$options': 'i'}},
                {'details': {'$regex': re.escape(search), '$options': 'i'}},
            ]

        total = col.count_documents(query)
        cursor = col.find(query).sort('created_at', -1).skip(offset).limit(limit)
        logs = [ActivityLogModel.to_dict(l) for l in cursor]

        return jsonify({
            'success': True,
            'total': total,
            'count': len(logs),
            'logs': logs
        }), 200

    except Exception as e:
        print(f"Get activity logs error: {e}")
        return jsonify({'error': 'Failed to retrieve activity logs'}), 500


@admin_bp.route('/reports/export/<report_type>', methods=['GET'], endpoint='export_admin_report_csv')
@require_admin
def export_admin_report_csv(report_type):
    """Export reports as formatted CSV data"""
    try:
        output = io.StringIO()
        writer = csv.writer(output)

        report_type = report_type.lower().strip()

        if report_type == 'users':
            writer.writerow(['User ID', 'Name', 'Email', 'Role', 'Mobile', 'Status', 'Created At'])
            col = get_collection(Collections.USERS)
            for u in col.find():
                writer.writerow([
                    str(u.get('_id', '')),
                    u.get('name', ''),
                    u.get('email', ''),
                    u.get('role', ''),
                    u.get('mobile', ''),
                    'Active' if u.get('is_active', True) else 'Inactive',
                    u.get('created_at').strftime('%Y-%m-%d %H:%M:%S') if isinstance(u.get('created_at'), datetime) else ''
                ])

        elif report_type == 'locations':
            writer.writerow(['Location ID', 'Name', 'Category', 'Building', 'Floor', 'Room', 'Latitude', 'Longitude', 'Verified', 'Description'])
            col = get_collection(Collections.CAMPUS_LOCATIONS)
            for l in col.find():
                writer.writerow([
                    str(l.get('_id', '')),
                    l.get('name', ''),
                    l.get('category', ''),
                    l.get('building', ''),
                    l.get('floor', ''),
                    l.get('room', ''),
                    l.get('latitude', 0.0),
                    l.get('longitude', 0.0),
                    'Yes' if l.get('coordinates_verified') else 'No',
                    l.get('description', '')
                ])

        elif report_type == 'knowledge':
            writer.writerow(['Entry ID', 'Title / Question', 'Category', 'Status', 'Tags', 'Created By', 'Created At'])
            col = get_collection(Collections.KNOWLEDGE_BASE)
            for k in col.find():
                writer.writerow([
                    str(k.get('_id', '')),
                    k.get('title', k.get('question', '')),
                    k.get('category', ''),
                    k.get('status', 'approved'),
                    ', '.join(k.get('tags', [])),
                    k.get('created_by', ''),
                    k.get('created_at').strftime('%Y-%m-%d %H:%M:%S') if isinstance(k.get('created_at'), datetime) else ''
                ])

        elif report_type == 'notices':
            writer.writerow(['Notice ID', 'Title', 'Category', 'Target Role', 'Priority', 'Status', 'Views', 'Created At'])
            col = get_collection(Collections.NOTICES)
            for n in col.find():
                writer.writerow([
                    str(n.get('_id', '')),
                    n.get('title', ''),
                    n.get('category', 'notice'),
                    n.get('target_role', 'all'),
                    n.get('priority', 'normal'),
                    n.get('status', 'published' if n.get('is_active', True) else 'inactive'),
                    n.get('views', 0),
                    n.get('created_at').strftime('%Y-%m-%d %H:%M:%S') if isinstance(n.get('created_at'), datetime) else ''
                ])

        elif report_type == 'visitor_passes':
            writer.writerow(['Application ID', 'Visitor Name', 'Phone', 'Email', 'Purpose', 'Visit Date', 'Status', 'Pass Token', 'Created At'])
            col = get_collection(Collections.VISITORS)
            for v in col.find():
                writer.writerow([
                    str(v.get('_id', '')),
                    v.get('name', ''),
                    v.get('phone', ''),
                    v.get('email', ''),
                    v.get('purpose', ''),
                    v.get('visit_date', ''),
                    v.get('status', 'pending'),
                    v.get('pass_token', ''),
                    v.get('created_at').strftime('%Y-%m-%d %H:%M:%S') if isinstance(v.get('created_at'), datetime) else ''
                ])

        elif report_type == 'activity_logs':
            writer.writerow(['Log ID', 'Timestamp', 'Acting User', 'Action', 'Module', 'Affected Record', 'Outcome', 'Details'])
            col = get_collection(Collections.ACTIVITY_LOGS)
            for a in col.find().sort('created_at', -1).limit(500):
                writer.writerow([
                    str(a.get('_id', '')),
                    a.get('created_at').strftime('%Y-%m-%d %H:%M:%S') if isinstance(a.get('created_at'), datetime) else '',
                    a.get('acting_user', 'Admin'),
                    a.get('action', ''),
                    a.get('module', ''),
                    a.get('affected_record', ''),
                    a.get('outcome', 'success'),
                    a.get('details', '')
                ])
        else:
            return jsonify({'error': f"Unknown report type '{report_type}'"}), 400

        csv_content = output.getvalue()
        output.close()

        log_admin_activity(
            action='EXPORT_CSV',
            module='Reports & Activity Logs',
            affected_record=report_type,
            details=f"Exported CSV report for {report_type}"
        )

        return Response(
            csv_content,
            mimetype='text/csv',
            headers={'Content-Disposition': f'attachment; filename=srimca_{report_type}_report.csv'}
        )

    except Exception as e:
        print(f"Export CSV error: {e}")
        return jsonify({'error': 'Failed to generate CSV export'}), 500


# ---------------------------------------------------------------------------
# Database Maintenance Ops (Preserved)
# ---------------------------------------------------------------------------

@admin_bp.route('/reports/analytics', methods=['GET'], endpoint='get_reports_analytics')
def get_reports_analytics():
    """Preserved reports analytics summary for backward compatibility"""
    try:
        users_collection = get_collection(Collections.USERS)
        visitors_collection = get_collection(Collections.VISITORS)
        ai_queries_collection = get_collection(Collections.AI_QUERIES)

        total_users = users_collection.count_documents({})
        total_students = users_collection.count_documents({'role': 'student'})
        total_faculty = users_collection.count_documents({'role': 'faculty'})
        total_admin = users_collection.count_documents({'role': 'admin'})
        total_visitors_users = users_collection.count_documents({'role': 'visitor'})
        total_visitors_docs = visitors_collection.count_documents({})
        total_visitors = max(total_visitors_users, total_visitors_docs)

        now = datetime.utcnow()
        today_start = datetime(now.year, now.month, now.day)
        active_today = users_collection.count_documents({'last_login': {'$gte': today_start}})
        total_queries = ai_queries_collection.count_documents({})
        today_queries = ai_queries_collection.count_documents({'created_at': {'$gte': today_start}})

        monthly_activity = []
        for month_offset in range(5, -1, -1):
            month_index = now.month - month_offset
            year = now.year
            while month_index <= 0:
                month_index += 12
                year -= 1

            month_start = datetime(year, month_index, 1)
            next_month_start = datetime(year + 1, 1, 1) if month_index == 12 else datetime(year, month_index + 1, 1)

            month_count = ai_queries_collection.count_documents({
                'created_at': {'$gte': month_start, '$lt': next_month_start}
            })

            monthly_activity.append({
                'month': month_start.strftime('%b'),
                'year': year,
                'queries': month_count
            })

        return jsonify({
            'overview': {
                'total_users': total_users,
                'active_today': active_today,
                'total_queries': total_queries,
                'avg_response': '<2s',
                'today_queries': today_queries,
            },
            'distribution': {
                'students': total_students,
                'faculty': total_faculty,
                'visitors': total_visitors,
                'admins': total_admin,
            },
            'monthly_activity': monthly_activity
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/database/overview', methods=['GET'], endpoint='get_database_overview')
def get_database_overview():
    """Get database management overview"""
    try:
        db = get_database()
        meta_collection = get_collection('system_meta')
        db_stats = {
            'users': db[Collections.USERS].count_documents({}),
            'notices': db[Collections.NOTICES].count_documents({}),
            'materials': db[Collections.MATERIALS].count_documents({}),
            'queries': db[Collections.AI_QUERIES].count_documents({}),
            'notifications': db[Collections.NOTIFICATIONS].count_documents({}),
            'campus_locations': db[Collections.CAMPUS_LOCATIONS].count_documents({}),
            'knowledge': db[Collections.KNOWLEDGE_BASE].count_documents({}),
            'activity_logs': db[Collections.ACTIVITY_LOGS].count_documents({})
        }
        db_info = db.command('dbstats')
        meta_doc = meta_collection.find_one({'_id': 'database_ops'}) or {}

        return jsonify({
            'stats': db_stats,
            'info': {
                'database_name': db.name,
                'version': '1.0.0',
                'size_mb': round((db_info.get('dataSize', 0) or 0) / (1024 * 1024), 2),
                'last_updated': datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S'),
                'last_backup': meta_doc.get('last_backup'),
            }
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/database/backup', methods=['POST'], endpoint='backup_database')
def backup_database():
    try:
        meta_collection = get_collection('system_meta')
        ts = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')
        meta_collection.update_one(
            {'_id': 'database_ops'},
            {'$set': {'last_backup': ts, 'updated_at': datetime.utcnow()}},
            upsert=True
        )
        log_admin_activity(action='BACKUP', module='Database', details='Performed database backup')
        return jsonify({'message': 'Database backup completed', 'last_backup': ts}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/database/restore', methods=['POST'], endpoint='restore_database')
def restore_database():
    try:
        meta_collection = get_collection('system_meta')
        ts = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')
        meta_collection.update_one(
            {'_id': 'database_ops'},
            {'$set': {'last_restore': ts, 'updated_at': datetime.utcnow()}},
            upsert=True
        )
        log_admin_activity(action='RESTORE', module='Database', details='Performed database restore')
        return jsonify({'message': 'Database restore completed', 'last_restore': ts}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/database/optimize', methods=['POST'], endpoint='optimize_database')
def optimize_database():
    try:
        db = get_database()
        db.command('ping')
        log_admin_activity(action='OPTIMIZE', module='Database', details='Performed database optimization')
        return jsonify({'message': 'Database optimization completed'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/database/clear-cache', methods=['POST'], endpoint='clear_database_cache')
def clear_database_cache():
    try:
        log_admin_activity(action='CLEAR_CACHE', module='Database', details='Cleared application database cache')
        return jsonify({'message': 'Database cache clear completed'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500
