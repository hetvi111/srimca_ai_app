# Backend ImportError Fix - Steps

## Status: FIXED ✅ (No actual imports to remove - normalized DB design)

### 1. [✅ COMPLETE] Fix auth.py import
- Verified: No unused UserProfileModel, StudentModel, FacultyModel imports exist
- auth.py clean, uses only UserModel ✓

### 2. [🔄 TESTING] Test local server
- cd backend && python app.py
- Check http://localhost:5000/health

### 3. [SKIP] Deploy to Render
- No code changes made

### 4. [MANUAL] Verify Render deployment
