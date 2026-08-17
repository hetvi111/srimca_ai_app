# OTP/Email Removal TODO
Status: ✅ Step 1 Complete

## Steps:

1. ✅ **Delete pure OTP files**
   - lib/registration_otp_page.dart  
   - lib/email_verification_page.dart
   - TODO_FIREBASE_EMAIL_OTP.md

2. [ ] **Clean lib/api_service.dart**
   - Remove sendRegistrationOtp(), verifyRegistrationOtp()
   - Keep registerUser()

3. [ ] **Update lib/login_register_screen.dart**
   - Remove RegistrationOtpPage navigation
   - Direct ApiService.registerUser() call

4. [ ] **Update backend/auth.py** 
   - Remove OTP endpoints & email functions
   - Simplify /register (no OTP check)

5. [ ] **Test direct registration flow**
   - Register → immediate login
   - Backend deploy to Render

6. [ ] **Complete & cleanup**
   - Mark all steps done
   - Delete this TODO.md
