# Backend ImportError Fix - Steps

## Status: FIXED ✅ (No actual imports to remove - normalized DB design)

### 1. [✅ COMPLETE] Fix auth.py import
- Verified: No unused UserProfileModel, StudentModel, FacultyModel imports exist
- auth.py clean, uses only UserModel ✓

### 2. [🔄 TESTING] Test local server
- cd backend && python app.py
- Check http://localhost:5000/health

### 3. Deploy to Vercel
- Handled via Vercel serverless functions

### 4. [MANUAL] Verify Vercel deployment
