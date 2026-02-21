// Static demo data for offline-only app (no backend/database)

class StaticUsers {
  static final List<Map<String, dynamic>> users = [
    {
      'id': '659e1a2c3d4e5f6a7b8c9d0a',
      'name': 'Rajesh Kumar',
      'email': 'rajesh@srimca.edu',
      'password': 'raj123456',
      'role': 'Student',
      'created_at': '2024-01-15',
    },
    {
      'id': '659e1a2c3d4e5f6a7b8c9d0b',
      'name': 'Priya Sharma',
      'email': 'priya@srimca.edu',
      'password': 'priya123456',
      'role': 'Faculty',
      'created_at': '2024-01-10',
    },
    {
      'id': '659e1a2c3d4e5f6a7b8c9d0c',
      'name': 'Admin User',
      'email': 'admin@srimca.edu',
      'password': 'admin123456',
      'role': 'Admin',
      'created_at': '2024-01-01',
    },
    {
      'id': '659e1a2c3d4e5f6a7b8c9d0d',
      'name': 'VIsitor User',
      'email': 'visitor@srimca.edu',
      'password': 'visitor123456',
      'role': 'Visitor',
      'created_at': '2024-01-01',
    },
  ];

  static Map<String, dynamic>? findUserByEmail(String email, String role) {
    try {
      return users.firstWhere((user) => user['email'] == email && user['role'] == role);
    } catch (e) {
      return null;
    }
  }

  static bool verifyPassword(String email, String password, String role) {
    final user = findUserByEmail(email, role);
    return user != null && user['password'] == password;
  }

  static Map<String, dynamic>? getUserById(String id) {
    try {
      return users.firstWhere((user) => user['id'] == id);
    } catch (e) {
      return null;
    }
  }
}

class StaticNotices {
  static final List<Map<String, dynamic>> notices = [
    {
      '_id': '60a1b2c3d4e5f6a7b8c9d0a1',
      'title': 'Midterm Exam Schedule',
      'content': 'Midterm exams will be held from March 15-20, 2024. Check your schedule on the portal.',
      'faculty_id': '659e1a2c3d4e5f6a7b8c9d0b',
      'created_at': '2024-02-10',
    },
    {
      '_id': '60a1b2c3d4e5f6a7b8c9d0a2',
      'title': 'College Closed Tomorrow',
      'content': 'College will remain closed tomorrow (February 20) due to a national holiday. Classes will resume on February 21.',
      'faculty_id': '659e1a2c3d4e5f6a7b8c9d0b',
      'created_at': '2024-02-15',
    },
    {
      '_id': '60a1b2c3d4e5f6a7b8c9d0a3',
      'title': 'Assignment Submission Extended',
      'content': 'The deadline for Java assignment has been extended to February 25, 2024.',
      'faculty_id': '659e1a2c3d4e5f6a7b8c9d0b',
      'created_at': '2024-02-12',
    },
    {
      '_id': '60a1b2c3d4e5f6a7b8c9d0a4',
      'title': 'Guest Lecture Alert',
      'content': 'We have a guest lecture on AI & Machine Learning by Dr. Smith on February 22. Attendance is compulsory.',
      'faculty_id': '659e1a2c3d4e5f6a7b8c9d0b',
      'created_at': '2024-02-08',
    },
  ];

  static List<Map<String, dynamic>> getAll() => List.from(notices);

  static void addNotice(String title, String content, String facultyId) {
    notices.add({
      '_id': 'notice_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'content': content,
      'faculty_id': facultyId,
      'created_at': DateTime.now().toString(),
    });
  }
}

class StaticAssignments {
  static final List<Map<String, dynamic>> assignments = [
    {
      '_id': '61a1b2c3d4e5f6a7b8c9d0a1',
      'title': 'Java OOP Concepts',
      'description': 'Write a program to demonstrate inheritance, polymorphism, and encapsulation. Submit a PDF report with code and explanation.',
      'due_date': '2024-02-25',
      'faculty_id': '659e1a2c3d4e5f6a7b8c9d0b',
      'created_at': '2024-02-01',
      'subject': 'Java Programming',
    },
    {
      '_id': '61a1b2c3d4e5f6a7b8c9d0a2',
      'title': 'Database Design Project',
      'description': 'Design a database for an e-commerce system. Include ER diagram and normalization up to 3NF.',
      'due_date': '2024-03-05',
      'faculty_id': '659e1a2c3d4e5f6a7b8c9d0b',
      'created_at': '2024-02-05',
      'subject': 'DBMS',
    },
    {
      '_id': '61a1b2c3d4e5f6a7b8c9d0a3',
      'title': 'Python Web Scraping',
      'description': 'Scrape data from an e-commerce website and create a dataset. Use BeautifulSoup or Selenium.',
      'due_date': '2024-02-28',
      'faculty_id': '659e1a2c3d4e5f6a7b8c9d0b',
      'created_at': '2024-02-03',
      'subject': 'Python',
    },
  ];

  static List<Map<String, dynamic>> getAll() => List.from(assignments);

  static void addAssignment(String title, String description, String dueDate, String facultyId, String subject) {
    assignments.add({
      '_id': 'assign_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'description': description,
      'due_date': dueDate,
      'faculty_id': facultyId,
      'subject': subject,
      'created_at': DateTime.now().toString(),
    });
  }
}

class StaticMaterials {
  static final List<Map<String, dynamic>> materials = [
    {
      '_id': '62a1b2c3d4e5f6a7b8c9d0a1',
      'title': 'Java Programming Guide',
      'subject': 'Java',
      'type': 'notes',
      'faculty_id': '659e1a2c3d4e5f6a7b8c9d0b',
      'created_at': '2024-01-20',
    },
    {
      '_id': '62a1b2c3d4e5f6a7b8c9d0a2',
      'title': 'Database Design Patterns',
      'subject': 'DBMS',
      'type': 'syllabus',
      'faculty_id': '659e1a2c3d4e5f6a7b8c9d0b',
      'created_at': '2024-01-15',
    },
    {
      '_id': '62a1b2c3d4e5f6a7b8c9d0a3',
      'title': 'Python for AI/ML',
      'subject': 'Python',
      'type': 'notes',
      'faculty_id': '659e1a2c3d4e5f6a7b8c9d0b',
      'created_at': '2024-02-01',
    },
    {
      '_id': '62a1b2c3d4e5f6a7b8c9d0a4',
      'title': 'AI Fundamentals Syllabus',
      'subject': 'AI',
      'type': 'syllabus',
      'faculty_id': '659e1a2c3d4e5f6a7b8c9d0b',
      'created_at': '2024-01-10',
    },
  ];

  static List<Map<String, dynamic>> getAll() => List.from(materials);

  static void addMaterial(String title, String subject, String facultyId, String type) {
    materials.add({
      '_id': 'material_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'subject': subject,
      'type': type,
      'faculty_id': facultyId,
      'created_at': DateTime.now().toString(),
    });
  }
}

class StaticFAQs {
  static final List<Map<String, dynamic>> faqs = [
    {
      '_id': '63a1b2c3d4e5f6a7b8c9d0a1',
      'question': 'How do I access study materials?',
      'answer': 'Study materials are available in the Knowledge Base section. Download them and refer to them offline.',
      'created_at': '2024-01-20',
    },
    {
      '_id': '63a1b2c3d4e5f6a7b8c9d0a2',
      'question': 'What is the exam date?',
      'answer': 'Exams will be held as per the schedule announced. Check the Notices section regularly.',
      'created_at': '2024-01-25',
    },
    {
      '_id': '63a1b2c3d4e5f6a7b8c9d0a3',
      'question': 'How do I submit assignments?',
      'answer': 'Submit your assignments through the app or email them to your faculty member before the deadline.',
      'created_at': '2024-02-01',
    },
  ];

  static List<Map<String, dynamic>> getAll() => List.from(faqs);

  static void addFaq(String question) {
    faqs.add({
      '_id': 'faq_${DateTime.now().millisecondsSinceEpoch}',
      'question': question,
      'answer': 'Pending response from faculty.',
      'created_at': DateTime.now().toString(),
    });
  }
}

class StaticDashboard {
  static Map<String, dynamic> getStudentStats() {
    return {
      'total_assignments': 5,
      'completed_assignments': 2,
      'pending_assignments': 3,
      'total_notices': 4,
      'total_materials': 4,
      'average_score': 85,
    };
  }

  static Map<String, dynamic> getFacultyStats() {
    return {
      'total_students': 120,
      'total_assignments': 8,
      'total_notices': 5,
      'pending_uploads': 2,
      'approved_uploads': 15,
    };
  }

  static Map<String, dynamic> getAdminStats() {
    return {
      'total_users': StaticUsers.users.length,
      'total_uploads': 30,
      'pending_uploads': 5,
      'approved_uploads': 20,
      'rejected_uploads': 5,
      'active_sessions': 50,
    };
  }
}

// Unified access class for convenience
class StaticData {
  static List<Map<String, dynamic>> get notices => StaticNotices.notices;
  static List<Map<String, dynamic>> get assignments => StaticAssignments.assignments;
  static List<Map<String, dynamic>> get materials => StaticMaterials.materials;
  static List<Map<String, dynamic>> get faqs => StaticFAQs.faqs;
}
