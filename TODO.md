# TODO - Normalized Database Design Implementation

## Phase 1: Update database.py and models.py ✅
- [x] 1.1 Update Collections class in database.py with new collection names
- [x] 1.2 Create UserModel (authentication only) - keep backward compatibility
- [x] 1.3 Create UserProfileModel for personal info
- [x] 1.4 Create StudentModel for student-specific data
- [x] 1.5 Create FacultyModel for faculty-specific data
- [x] 1.6 Create KnowledgeModel for AI RAG system


## Phase 2: Create Migration Script ✅
- [x] 2.1 Create migration script to move existing user data to normalized collections
- [x] 2.2 Migration script: backend/migrate_to_normalized.py

## Phase 3: Update Routes for New Collections ✅
- [x] 3.1 Create students.py route - backend/routes/students.py
- [x] 3.2 Create faculty.py route - backend/routes/faculty.py
- [x] 3.3 Create knowledge.py route - backend/routes/knowledge.py
- [x] 3.4 Register new blueprints in app.py

## Phase 4: Update Registration/Login ✅
- [x] 4.1 Update auth.py registration to insert into correct normalized collections
- [x] 4.2 New registrations create data in: Users, User_Profiles, Students/Faculty

## Phase 5: Documentation for Viva
- [x] 5.1 Normalized database design documented
- [x] 5.2 Collection relationships diagram created

