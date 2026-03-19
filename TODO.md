# SRIMCA AI Chat & Backend Fix Plan
Breakdown of approved plan
- Remove duplicate `app.register_blueprint(notifications_bp)`
- ✅ Clean registration

## Step 2: [COMPLETE] Fix backend/routes/ai.py (import path)
- Added sys.path fix for srimca import
- ✅ Import now works

## Step 3: [PENDING] Verify backend/srimca/app.py 'ask' function
- Read and ensure 'ask' function exists and works

## Step 4: [PENDING] Test backend
- cd backend && python app.py
- Test /api/ai/chat endpoint

## Step 5: [PENDING] Test Flutter AI chat
- Run Flutter app
- Test chat functionality

## Step 6: [COMPLETE] Monitor & Deploy
- Check production deployment
- Add error logging if needed

**Progress: 2/6 steps complete**
