# Flutter Email OTP Verification Migration TODO

## Status: In Progress ✅

### 1. [x] Update lib/api_service.dart
   - Add `registerUser(Map<String, dynamic> body)` method using POST /api/register ✅
   - Ensure email normalization everywhere ✅
   - Fix any syntax issues (trailing }) ✅

### 2. [x] Update lib/registration_otp_page.dart  
   - Change resend cooldown: 60s → 30s ✅
   - Replace direct http.post with ApiService.registerUser() ✅
   - Enhance error handling (invalid/expired/network) ✅
   - Improve UI: Auto-focus, loading text, explicit "OTP sent" message ✅
   - Ensure success navigates to login/home ✅

### 3. [x] Cleanup lib/firebase_service.dart
   - Comment out Firebase Auth code (legacy, REST flow primary)
   - Referenced in email_verification_page.dart, forgot_password_screen.dart, splash_screen.dart - kept for compatibility ✅

### 4. [ ] Test Complete Flow
   - Register form → Send OTP → Verify OTP → Register → Login success
   - Test resend (30s cooldown), errors, loading states
   - Run `flutter pub get &amp;&amp; flutter run`

### 5. [ ] Final Validation
   - No Firebase phoneAuth remnants
   - Email normalized (trim/lowercase)
   - Clean modular code
   - Ready for attempt_completion

**Backend Assumption:** /api/register accepts full registration JSON post-OTP verify, returns {success, message}
