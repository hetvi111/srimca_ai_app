"""
Data models for MongoDB collections
Defines document structures for normalized database design

Collections:
- Users: Authentication data only
- User_Profiles: Personal information (phone, address)
- Students: Student-specific data (semester, department, enrollment)
- Faculty: Faculty-specific data (department, designation)
- Knowledge: AI RAG knowledge base
- Notices, Assignments, Materials, FAQs, AI_Queries: Content and activity data
"""

from datetime import datetime
from bson import ObjectId
from database import Collections


# ============================================================================
# NORMALIZED MODELS - Following Database Normalization Principles (1NF-3NF)
# ============================================================================

class UserModel:
    """
    User model for AUTHENTICATION ONLY
    This is the PRIMARY model for login/authentication
    
    Normalization: 1NF - Contains only atomic values for auth fields
    """
    
    collection_name = Collections.USERS
    
    @staticmethod
    def create_user(name: str, email: str, password: str, role: str = 'student'):
        """
        Create a new user document (authentication data only)
        
        NOTE: Profile data is now stored in User_Profile collection
              Student data is stored in Students collection
              Faculty data is stored in Faculty collection
        """
        return {
            'name': name,
            'email': email.lower(),
            'password': password,  # Should be hashed before storing
            'role': role.lower(),
            'created_at': datetime.utcnow(),
            'updated_at': datetime.utcnow(),
            'is_active': True,
            'last_login': None
            # DEPRECATED: 'profile' field is now in User_Profile collection
            # Keeping for backward compatibility during migration
        }
    
    @staticmethod
    def to_dict(user_doc, include_deprecated_profile=False):
        """
        Convert user document to dictionary (without password)
        
        Args:
            user_doc: MongoDB document
            include_deprecated_profile: If True, includes legacy profile field for backward compatibility
        """
        if user_doc is None:
            return None
        
        result = {
            '_id': str(user_doc.get('_id', '')),
            'name': user_doc.get('name', ''),
            'email': user_doc.get('email', ''),
            'role': user_doc.get('role', ''),
            'created_at': user_doc.get('created_at').isoformat() if user_doc.get('created_at') else None,
            'is_active': user_doc.get('is_active', True),
            'last_login': user_doc.get('last_login').isoformat() if user_doc.get('last_login') else None
        }
        
        # Include all additional fields if they exist
        if 'mobile' in user_doc:
            result['mobile'] = user_doc.get('mobile', '')
        if 'address' in user_doc:
            result['address'] = user_doc.get('address', '')
        if 'enrollment' in user_doc:
            result['enrollment'] = user_doc.get('enrollment', '')
        if 'dob' in user_doc:
            result['dob'] = user_doc.get('dob', '')
        if 'semester' in user_doc:
            result['semester'] = user_doc.get('semester', '')
        if 'department' in user_doc:
            result['department'] = user_doc.get('department', '')
        if 'designation' in user_doc:
            result['designation'] = user_doc.get('designation', '')
        if 'purpose' in user_doc:
            result['purpose'] = user_doc.get('purpose', '')
        if 'visit_date' in user_doc:
            result['visit_date'] = user_doc.get('visit_date', '')
        if 'approval_status' in user_doc:
            result['approval_status'] = user_doc.get('approval_status', '')
        
        # Backward compatibility - include profile if it exists and requested
        if include_deprecated_profile and 'profile' in user_doc:
            result['profile'] = user_doc.get('profile', {})
        
        return result


class UserProfileModel:
    """
    User Profile model for PERSONAL INFORMATION
    
    Normalization: 2NF - No partial dependencies, linked to Users by user_id
    This separates personal info from authentication data
    """
    
    collection_name = Collections.USER_PROFILES
    
    @staticmethod
    def create_profile(user_id: str, phone: str = '', address: str = ''):
        """
        Create a new user profile document
        
        Args:
            user_id: Reference to Users collection (_id)
            phone: Phone number
            address: Address
        """
        return {
            'user_id': user_id,
            'phone': phone,
            'address': address,
            'created_at': datetime.utcnow(),
            'updated_at': datetime.utcnow()
        }
    
    @staticmethod
    def to_dict(profile_doc):
        """Convert profile document to dictionary"""
        if profile_doc is None:
            return None
        
        return {
            '_id': str(profile_doc.get('_id', '')),
            'user_id': str(profile_doc.get('user_id', '')),
            'phone': profile_doc.get('phone', ''),
            'address': profile_doc.get('address', ''),
            'created_at': profile_doc.get('created_at').isoformat() if profile_doc.get('created_at') else None,
            'updated_at': profile_doc.get('updated_at').isoformat() if profile_doc.get('updated_at') else None
        }


class StudentModel:
    """
    Student model for STUDENT-SPECIFIC DATA
    
    Normalization: 3NF - No transitive dependencies
    Stores academic information separate from personal and auth data
    
    Example: { "user_id": "U001", "semester": "5", "department": "BCA", "enrollment_number": "SRIMCA2023BCA015" }
    """
    
    collection_name = Collections.STUDENTS
    
    @staticmethod
    def create_student(user_id: str, semester: str, department: str, enrollment_number: str):
        """
        Create a new student document
        
        Args:
            user_id: Reference to Users collection (_id)
            semester: Current semester (1-8)
            department: Department name (BCA, MCA, BBA, MBA)
            enrollment_number: Unique enrollment number
        """
        return {
            'user_id': user_id,
            'semester': semester,
            'department': department,
            'enrollment_number': enrollment_number,
            'created_at': datetime.utcnow(),
            'updated_at': datetime.utcnow()
        }
    
    @staticmethod
    def to_dict(student_doc):
        """Convert student document to dictionary"""
        if student_doc is None:
            return None
        
        return {
            '_id': str(student_doc.get('_id', '')),
            'user_id': str(student_doc.get('user_id', '')),
            'semester': student_doc.get('semester', ''),
            'department': student_doc.get('department', ''),
            'enrollment_number': student_doc.get('enrollment_number', ''),
            'created_at': student_doc.get('created_at').isoformat() if student_doc.get('created_at') else None,
            'updated_at': student_doc.get('updated_at').isoformat() if student_doc.get('updated_at') else None
        }


class FacultyModel:
    """
    Faculty model for FACULTY-SPECIFIC DATA
    
    Normalization: 3NF - No transitive dependencies
    Stores professional information separate from personal and auth data
    
    Example: { "user_id": "U003", "department": "Computer Application", "designation": "Assistant Professor" }
    """
    
    collection_name = Collections.FACULTIES
    
    @staticmethod
    def create_faculty(user_id: str, department: str, designation: str):
        """
        Create a new faculty document
        
        Args:
            user_id: Reference to Users collection (_id)
            department: Department name
            designation: Job designation (Professor, Assistant Professor, etc.)
        """
        return {
            'user_id': user_id,
            'department': department,
            'designation': designation,
            'created_at': datetime.utcnow(),
            'updated_at': datetime.utcnow()
        }
    
    @staticmethod
    def to_dict(faculty_doc):
        """Convert faculty document to dictionary"""
        if faculty_doc is None:
            return None
        
        return {
            '_id': str(faculty_doc.get('_id', '')),
            'user_id': str(faculty_doc.get('user_id', '')),
            'department': faculty_doc.get('department', ''),
            'designation': faculty_doc.get('designation', ''),
            'created_at': faculty_doc.get('created_at').isoformat() if faculty_doc.get('created_at') else None,
            'updated_at': faculty_doc.get('updated_at').isoformat() if faculty_doc.get('updated_at') else None
        }


class KnowledgeModel:
    """
    Knowledge model for AI RAG (Retrieval-Augmented Generation) system
    
    This stores the knowledge base used by the AI chatbot to answer questions
    Optimized for vector search and semantic matching
    
    Example: { "question": "What is SRIMCA?", "answer": "SRIMCA stands for...", "category": "about", "embedding": [...] }
    """
    
    collection_name = Collections.KNOWLEDGE
    
    @staticmethod
    def create_knowledge(question: str, answer: str, category: str = 'general', embedding: list = None):
        """
        Create a new knowledge base document
        
        Args:
            question: Question/query text
            answer: Answer/response text
            category: Category (about, courses, admission, contact, etc.)
            embedding: Vector embedding for semantic search (optional)
        """
        return {
            'question': question,
            'answer': answer,
            'category': category,
            'embedding': embedding if embedding else [],  # For vector search
            'created_at': datetime.utcnow(),
            'updated_at': datetime.utcnow(),
            'is_active': True,
            'usage_count': 0
        }
    
    @staticmethod
    def to_dict(knowledge_doc):
        """Convert knowledge document to dictionary"""
        if knowledge_doc is None:
            return None
        
        return {
            '_id': str(knowledge_doc.get('_id', '')),
            'question': knowledge_doc.get('question', ''),
            'answer': knowledge_doc.get('answer', ''),
            'category': knowledge_doc.get('category', 'general'),
            'embedding': knowledge_doc.get('embedding', []),
            'created_at': knowledge_doc.get('created_at').isoformat() if knowledge_doc.get('created_at') else None,
            'updated_at': knowledge_doc.get('updated_at').isoformat() if knowledge_doc.get('updated_at') else None,
            'is_active': knowledge_doc.get('is_active', True),
            'usage_count': knowledge_doc.get('usage_count', 0)
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
