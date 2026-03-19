# Visitor Data Fix - Steps to Complete

## Status: Planning [IN PROGRESS]

### 1. [✅ COMPLETED] Fix Frontend Field Mapping
- Edited lib/visitor_management_page.dart 
- Visitor.fromMap now handles 'purpose' → visitPurpose
- Added debug logging in _loadVisitors()
- Verified with edit_file tool

### 2. [✅ COMPLETED] Create Sample Visitor Data
- Created backend/create_sample_visitors.py with 3 samples
- Run `cd backend && python create_sample_visitors.py` to populate DB

### 3. [PENDING] Test API Endpoint
- Test https://srimca-ai-app.onrender.com/api/admin/visitors
- Verify data returns correctly

### 4. [PENDING] Backend Verification
- Check if local backend running (port 5000)
- Start `cd backend && python app.py` if needed

### 5. [PENDING] Frontend Test
- Run Flutter app
- Navigate to Visitor Management page
- Verify data displays

### 6. [COMPLETED] Update TODO.md after each step

