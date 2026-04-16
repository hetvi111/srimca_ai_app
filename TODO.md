# Email Verification Improvements - Approved Plan
Status: 🚀 In Progress

## Breakdown of Steps (Sequential)

### 1. ✅ Create this TODO.md (Current)
### 2. ✅ Edit backend/auth.py
   - Add rate limiting to `/resend-verification-email` (60s cooldown) ✅
   - Add custom continue_url to `generate_email_verification_link` ✅
   - Upgrade `_send_verification_email` to HTML template ✅
### 3. 🧪 Test Backend Endpoints
   ```bash
   # Test rate limit (should fail within 60s)
   curl -X POST http://localhost:5000/api/resend-verification-email -H "Content-Type: application/json" -d '{"email":"test@example.com"}'
   
   # Test status sync
   curl -X POST http://localhost:5000/api/email-verification-status -H "Content-Type: application/json" -d '{"email":"test@example.com"}'
   ```
### 4. 🔄 Optional: Flutter API Integration
   - Add backend API calls in `lib/api_service.dart`
   - Update `lib/email_verification_page.dart` to use backend
### 5. ✅ Test Full Flow
   - Register → Verify email → Login
   - Resend (rate limited) → Status check
### 6. 🚀 Complete & Demo
   - Update TODO with [x]
   - Run `attempt_completion`

**Next Step: 🧪 Test Backend Endpoints**

