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
        
        return {
            '_id': str(user_doc.get('_id', '')),
            'name': user_doc.get('name', ''),
            'email': user_doc.get('email', ''),
            'role': user_doc.get('role', ''),
            'created_at': user_doc.get('created_at').isoformat() if user_doc.get('created_at') else None,
            'is_active': user_doc.get('is_active', True),
            'profile': user_doc.get('profile', {})
        }


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
