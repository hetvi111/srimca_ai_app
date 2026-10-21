"""
Data models for MongoDB collections
Defines document structures for Users, Notices, Assignments, Materials, FAQs
"""

from datetime import datetime
from bson import ObjectId
from database import Collections


class UserModel:
    """User model for authentication and profile management"""
    
    collection_name = Collections.USERS
    
    @staticmethod
    def create_user(name: str, email: str, password: str, role: str = 'student'):
        """
        Create a new user document
        """
        return {
            'name': name,
            'email': email.lower(),
            'password': password,  # Should be hashed before storing
            'role': role.lower(),
            'created_at': datetime.utcnow(),
            'updated_at': datetime.utcnow(),
            'is_active': True,
            'last_login': None,
            'profile': {
                'phone': '',
                'address': '',
                'semester': '',
                'department': '',
                'enrollment_number': ''
            }
        }
    
    @staticmethod
    def to_dict(user_doc):
        """Convert user document to dictionary (without password)"""
        if user_doc is None:
            return None
        
        result = {
            '_id': str(user_doc.get('_id', '')),
            'name': user_doc.get('name', ''),
            'email': user_doc.get('email', ''),
            'role': user_doc.get('role', ''),
            'created_at': user_doc.get('created_at').isoformat() if isinstance(user_doc.get('created_at'), datetime) else user_doc.get('created_at'),
            'is_active': user_doc.get('is_active', True),
            'profile': user_doc.get('profile', {})
        }
        # Include all other non-sensitive fields from user_doc
        exclude_fields = {'password', 'otp', 'otp_hash', 'otp_expires_at'}
        for k, v in user_doc.items():
            if k not in exclude_fields and k not in result:
                if isinstance(v, ObjectId):
                    result[k] = str(v)
                elif isinstance(v, datetime):
                    result[k] = v.isoformat()
                else:
                    result[k] = v
        return result


class NoticeModel:
    """Notice model for college notices"""
    
    collection_name = Collections.NOTICES
    
    @staticmethod
    def create_notice(title: str, content: str, faculty_id: str, priority: str = 'normal'):
        """
        Create a new notice document
        """
        return {
            'title': title,
            'content': content,
            'faculty_id': faculty_id,
            'priority': priority,  # normal, important, urgent
            'created_at': datetime.utcnow(),
            'updated_at': datetime.utcnow(),
            'is_active': True,
            'views': 0
        }
    
    @staticmethod
    def to_dict(notice_doc):
        """Convert notice document to dictionary"""
        if notice_doc is None:
            return None
        
        return {
            '_id': str(notice_doc.get('_id', '')),
            'title': notice_doc.get('title', ''),
            'content': notice_doc.get('content', ''),
            'faculty_id': str(notice_doc.get('faculty_id', '')),
            'priority': notice_doc.get('priority', 'normal'),
            'created_at': notice_doc.get('created_at').isoformat() if notice_doc.get('created_at') else None,
            'is_active': notice_doc.get('is_active', True),
            'views': notice_doc.get('views', 0)
        }


class AssignmentModel:
    """Assignment model for coursework assignments"""
    
    collection_name = Collections.ASSIGNMENTS
    
    @staticmethod
    def create_assignment(
        title: str,
        description: str,
        due_date: str,
        faculty_id: str,
        subject: str,
        max_marks: int = 100
    ):
        """
        Create a new assignment document
        """
        return {
            'title': title,
            'description': description,
            'due_date': due_date,
            'faculty_id': faculty_id,
            'subject': subject,
            'max_marks': max_marks,
            'created_at': datetime.utcnow(),
            'updated_at': datetime.utcnow(),
            'is_active': True,
            'submissions': []
        }
    
    @staticmethod
    def to_dict(assignment_doc):
        """Convert assignment document to dictionary"""
        if assignment_doc is None:
            return None
        
        return {
            '_id': str(assignment_doc.get('_id', '')),
            'title': assignment_doc.get('title', ''),
            'description': assignment_doc.get('description', ''),
            'due_date': assignment_doc.get('due_date', ''),
            'faculty_id': str(assignment_doc.get('faculty_id', '')),
            'subject': assignment_doc.get('subject', ''),
            'max_marks': assignment_doc.get('max_marks', 100),
            'created_at': assignment_doc.get('created_at').isoformat() if assignment_doc.get('created_at') else None,
            'is_active': assignment_doc.get('is_active', True)
        }


class MaterialModel:
    """Study material model for educational resources"""
    
    collection_name = Collections.MATERIALS
    
    @staticmethod
    def create_material(
        title: str,
        subject: str,
        type: str,
        faculty_id: str,
        file_url: str = '',
        description: str = ''
    ):
        """
        Create a new material document
        Types: notes, syllabus, paper, book, video
        """
        return {
            'title': title,
            'subject': subject,
            'type': type,  # notes, syllabus, paper, book, video
            'faculty_id': faculty_id,
            'file_url': file_url,
            'description': description,
            'created_at': datetime.utcnow(),
            'updated_at': datetime.utcnow(),
            'is_active': True,
            'downloads': 0
        }
    
    @staticmethod
    def to_dict(material_doc):
        """Convert material document to dictionary"""
        if material_doc is None:
            return None
        
        return {
            '_id': str(material_doc.get('_id', '')),
            'title': material_doc.get('title', ''),
            'subject': material_doc.get('subject', ''),
            'type': material_doc.get('type', ''),
            'faculty_id': str(material_doc.get('faculty_id', '')),
            'file_url': material_doc.get('file_url', ''),
            'description': material_doc.get('description', ''),
            'created_at': material_doc.get('created_at').isoformat() if material_doc.get('created_at') else None,
            'is_active': material_doc.get('is_active', True),
            'downloads': material_doc.get('downloads', 0)
        }


class FAQModel:
    """FAQ model for frequently asked questions"""
    
    collection_name = Collections.FAQS
    
    @staticmethod
    def create_faq(question: str, answer: str = '', created_by: str = ''):
        """
        Create a new FAQ document
        """
        return {
            'question': question,
            'answer': answer,
            'created_by': created_by,
            'created_at': datetime.utcnow(),
            'updated_at': datetime.utcnow(),
            'is_active': True,
            'views': 0
        }
    
    @staticmethod
    def to_dict(faq_doc):
        """Convert FAQ document to dictionary"""
        if faq_doc is None:
            return None
        
        return {
            '_id': str(faq_doc.get('_id', '')),
            'question': faq_doc.get('question', ''),
            'answer': faq_doc.get('answer', ''),
            'created_by': str(faq_doc.get('created_by', '')),
            'created_at': faq_doc.get('created_at').isoformat() if faq_doc.get('created_at') else None,
            'is_active': faq_doc.get('is_active', True),
            'views': faq_doc.get('views', 0)
        }


class AIQueryModel:
    """AI Query model for storing AI chat interactions"""
    
    collection_name = Collections.AI_QUERIES
    
    @staticmethod
    def create_query(user_id: str, query: str, response: str):
        """
        Create a new AI query document
        """
        return {
            'user_id': user_id,
            'query': query,
            'response': response,
            'created_at': datetime.utcnow(),
            'is_helpful': None  # Can be True, False, or None
        }
    
    @staticmethod
    def to_dict(query_doc):
        """Convert AI query document to dictionary"""
        if query_doc is None:
            return None
        
        return {
            '_id': str(query_doc.get('_id', '')),
            'user_id': str(query_doc.get('user_id', '')),
            'query': query_doc.get('query', ''),
            'response': query_doc.get('response', ''),
            'created_at': query_doc.get('created_at').isoformat() if query_doc.get('created_at') else None,
            'is_helpful': query_doc.get('is_helpful')
        }


class NotificationModel:
    """Notification model for role-based notifications"""

    collection_name = Collections.NOTIFICATIONS

    @staticmethod
    def create_notification(
        title: str,
        message: str,
        notification_type: str = 'info',
        target_role: str = 'all',
        sender_role: str = 'admin'
    ):
        return {
            'title': title,
            'message': message,
            'type': notification_type,
            'target_role': target_role,
            'sender_role': sender_role,
            'is_read': False,
            'created_at': datetime.utcnow()
        }

    @staticmethod
    def to_dict(notification_doc):
        if notification_doc is None:
            return None

        return {
            '_id': str(notification_doc.get('_id', '')),
            'title': notification_doc.get('title', ''),
            'message': notification_doc.get('message', ''),
            'type': notification_doc.get('type', 'info'),
            'target_role': notification_doc.get('target_role', 'all'),
            'sender_role': notification_doc.get('sender_role', 'admin'),
            'is_read': notification_doc.get('is_read', False),
            'created_at': notification_doc.get('created_at').isoformat() if notification_doc.get('created_at') else None
        }


class VisitorModel:
    """Visitor model for visitor inquiries/approvals"""

    collection_name = Collections.VISITORS

    @staticmethod
    def create_visitor(name: str, email: str = '', phone: str = '', purpose: str = ''):
        return {
            'name': name,
            'email': email.lower() if email else '',
            'phone': phone,
            'purpose': purpose,
            'status': 'pending',
            'created_at': datetime.utcnow()
        }

    @staticmethod
    def to_dict(visitor_doc):
        if visitor_doc is None:
            return None

        return {
            '_id': str(visitor_doc.get('_id', '')),
            'name': visitor_doc.get('name', ''),
            'email': visitor_doc.get('email', ''),
            'phone': visitor_doc.get('phone', ''),
            'purpose': visitor_doc.get('purpose', ''),
            'status': visitor_doc.get('status', 'pending'),
        'created_at': visitor_doc.get('created_at').isoformat() if visitor_doc.get('created_at') else None

        }


class VisitorLogModel:
 
    
    collection_name = Collections.VISITOR_LOGS
    
    @staticmethod
    def create_log(visitor_id: str, purpose: str = '', status: str = 'checked_in'):
        return {
            'visitor_id': visitor_id,
            'purpose': purpose,
            'status': status,
            'check_in_time': datetime.utcnow(),
            'check_out_time': None,
            'created_at': datetime.utcnow()
        }
    
    @staticmethod
    def to_dict(log_doc):
        if log_doc is None:
            return None
        return {
            '_id': str(log_doc.get('_id', '')),
            'visitor_id': str(log_doc.get('visitor_id', '')),
            'purpose': log_doc.get('purpose', ''),
            'status': log_doc.get('status', 'checked_in'),
            'check_in_time': log_doc.get('check_in_time').isoformat() if log_doc.get('check_in_time') else None,
            'check_out_time': log_doc.get('check_out_time').isoformat() if log_doc.get('check_out_time') else None,
            'created_at': log_doc.get('created_at').isoformat() if log_doc.get('created_at') else None
        }


class PasswordResetRequestModel:
    """Password reset request model for admin-controlled forgot password"""
    
    collection_name = Collections.PASSWORD_RESET_REQUESTS
    
    @staticmethod
    def create_request(email: str):
        """
        Create a new password reset request document
        """
        return {
            'email': email.lower(),
            'status': 'pending',
            'created_at': datetime.utcnow(),
            'updated_at': datetime.utcnow(),
            'reset_password': None  # Set after admin reset
        }
    
    @staticmethod
    def to_dict(request_doc):
        """Convert request document to dictionary"""
        if request_doc is None:
            return None
        
        return {
            '_id': str(request_doc.get('_id', '')),
            'email': request_doc.get('email', ''),
            'status': request_doc.get('status', 'pending'),
            'created_at': request_doc.get('created_at').isoformat() if request_doc.get('created_at') else None,
            'updated_at': request_doc.get('updated_at').isoformat() if request_doc.get('updated_at') else None,
            'reset_password': request_doc.get('reset_password', None)  # Temp PW for admin
        }


class CampusLocationModel:
    """Campus location model for automatic campus navigation"""

    collection_name = Collections.CAMPUS_LOCATIONS

    @staticmethod
    def create_location(
        name: str,
        latitude: float,
        longitude: float,
        description: str,
        aliases: list = None,
        building: str = '',
        floor: str = '',
        room: str = '',
        category: str = 'academic',
        coordinates_verified: bool = True
    ):
        """
        Create a new campus location document
        """
        now = datetime.utcnow()
        return {
            'name': name.strip(),
            'latitude': float(latitude) if latitude is not None else 0.0,
            'longitude': float(longitude) if longitude is not None else 0.0,
            'description': description.strip(),
            'aliases': [a.strip().lower() for a in (aliases or []) if a and a.strip()],
            'building': building.strip(),
            'floor': floor.strip(),
            'room': room.strip(),
            'category': category.strip(),
            'coordinates_verified': coordinates_verified,
            'created_at': now,
            'updated_at': now
        }

    @staticmethod
    def to_dict(location_doc):
        """Convert campus location document to dictionary"""
        if location_doc is None:
            return None

        return {
            '_id': str(location_doc.get('_id', '')),
            'name': location_doc.get('name', ''),
            'latitude': float(location_doc.get('latitude', 0.0) or 0.0),
            'longitude': float(location_doc.get('longitude', 0.0) or 0.0),
            'description': location_doc.get('description', ''),
            'aliases': location_doc.get('aliases', []),
            'building': location_doc.get('building', ''),
            'floor': location_doc.get('floor', ''),
            'room': location_doc.get('room', ''),
            'category': location_doc.get('category', 'academic'),
            'coordinates_verified': bool(location_doc.get('coordinates_verified', True)),
            'created_at': location_doc.get('created_at').isoformat() if isinstance(location_doc.get('created_at'), datetime) else location_doc.get('created_at'),
            'updated_at': location_doc.get('updated_at').isoformat() if isinstance(location_doc.get('updated_at'), datetime) else location_doc.get('updated_at')
        }


class KnowledgeBaseModel:
    """Knowledge base model for official college information used by AI Assistant"""

    collection_name = Collections.KNOWLEDGE_BASE

    @staticmethod
    def create_entry(
        title: str,
        text: str,
        category: str = 'general',
        tags: list = None,
        status: str = 'approved',
        created_by: str = 'admin'
    ):
        now = datetime.utcnow()
        return {
            'title': title.strip(),
            'text': text.strip(),
            'category': category.strip().lower(),
            'tags': [t.strip().lower() for t in (tags or []) if t and t.strip()],
            'status': status.strip().lower(),
            'created_by': created_by,
            'views': 0,
            'created_at': now,
            'updated_at': now
        }

    @staticmethod
    def to_dict(entry_doc):
        if entry_doc is None:
            return None
        return {
            '_id': str(entry_doc.get('_id', '')),
            'title': entry_doc.get('title', entry_doc.get('question', '')),
            'text': entry_doc.get('text', entry_doc.get('answer', '')),
            'category': entry_doc.get('category', 'general'),
            'tags': entry_doc.get('tags', []),
            'status': entry_doc.get('status', 'approved'),
            'created_by': str(entry_doc.get('created_by', 'admin')),
            'views': entry_doc.get('views', 0),
            'created_at': entry_doc.get('created_at').isoformat() if isinstance(entry_doc.get('created_at'), datetime) else entry_doc.get('created_at'),
            'updated_at': entry_doc.get('updated_at').isoformat() if isinstance(entry_doc.get('updated_at'), datetime) else entry_doc.get('updated_at')
        }


class ActivityLogModel:
    """Activity log model for admin actions and audit trail"""

    collection_name = Collections.ACTIVITY_LOGS

    @staticmethod
    def create_log(
        acting_user: str,
        action: str,
        module: str,
        affected_record: str = '',
        details: str = '',
        user_id: str = '',
        outcome: str = 'success'
    ):
        return {
            'acting_user': acting_user,
            'user_id': user_id,
            'action': action.upper(),
            'module': module,
            'affected_record': affected_record,
            'details': details,
            'outcome': outcome,
            'created_at': datetime.utcnow()
        }

    @staticmethod
    def to_dict(log_doc):
        if log_doc is None:
            return None
        return {
            '_id': str(log_doc.get('_id', '')),
            'acting_user': log_doc.get('acting_user', 'Admin'),
            'user_id': str(log_doc.get('user_id', '')),
            'action': log_doc.get('action', 'ACTION'),
            'module': log_doc.get('module', 'System'),
            'affected_record': log_doc.get('affected_record', ''),
            'details': log_doc.get('details', ''),
            'outcome': log_doc.get('outcome', 'success'),
            'created_at': log_doc.get('created_at').isoformat() if isinstance(log_doc.get('created_at'), datetime) else log_doc.get('created_at')
        }


class UnresolvedQueryModel:
    """Model for unanswered or unresolved user questions needing admin review"""

    collection_name = Collections.UNRESOLVED_QUERIES

    @staticmethod
    def create_query(
        question: str,
        user_id: str = '',
        user_role: str = 'student',
        status: str = 'pending'
    ):
        return {
            'question': question.strip(),
            'user_id': user_id,
            'user_role': user_role,
            'status': status,
            'approved_answer': '',
            'resolved_by': '',
            'created_at': datetime.utcnow(),
            'resolved_at': None
        }

    @staticmethod
    def to_dict(q_doc):
        if q_doc is None:
            return None
        return {
            '_id': str(q_doc.get('_id', '')),
            'question': q_doc.get('question', ''),
            'user_id': str(q_doc.get('user_id', '')),
            'user_role': q_doc.get('user_role', 'student'),
            'status': q_doc.get('status', 'pending'),
            'approved_answer': q_doc.get('approved_answer', ''),
            'resolved_by': str(q_doc.get('resolved_by', '')),
            'created_at': q_doc.get('created_at').isoformat() if isinstance(q_doc.get('created_at'), datetime) else q_doc.get('created_at'),
            'resolved_at': q_doc.get('resolved_at').isoformat() if isinstance(q_doc.get('resolved_at'), datetime) else q_doc.get('resolved_at')
        }


