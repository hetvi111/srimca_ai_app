# Backend ImportError Fix - Steps

## Status: Editing [IN PROGRESS]

### 1. [TODO] Fix auth.py import
- Remove unused UserProfileModel, StudentModel, FacultyModel imports

### 2. [TODO] Test local server
- cd backend && python app.py
- Check http://localhost:5000/health

### 3. [TODO] Deploy to Render
- git add . && git commit -m "Fix auth.py import error" && git push

### 4. [COMPLETED] Verify Render http://your-render-url/health
