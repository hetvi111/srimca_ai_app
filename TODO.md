# SRIMCA AI - Firebase Email OTP Migration TODO

Status: 🚀 IN PROGRESS (User approved plan)

## Completed (from previous analysis):
- [x] Steps 1-4 from TODO_FIREBASE_EMAIL_OTP.md (API helpers, OTP page, login_register updates)

## Migration Plan Steps:

### Backend Changes (auth.py)
1. [✅] Update `/register` endpoint:
   - Set `email_verified: True` after OTP verification
   - Skip Firebase verification link generation/sending
   - Keep Firebase user creation (optional)

2. [✅] Update `/login` endpoint:
   - Remove Firebase `email_verified` check
   - Trust MongoDB `email_verified = True`


### Frontend Cleanups
3. [✅] lib/firebase_service.dart:
   - Deprecate/remove email verification methods

4. [✅] lib/registration_otp_page.dart:
   - Confirmed: Uses backend API only, no Firebase

5. [✅] lib/email_verification_page.dart:
   - Route & import removed (file can be deleted later)

6. [✅] lib/main.dart:
   - '/email-verification' route removed

### Testing & Completion
7. [ ] Test full flow: Register → OTP → Login (no Firebase link needed)
8. [ ] Update TODO_FIREBASE_EMAIL_OTP.md → ✅ COMPLETE
9. [ ] attempt_completion

**Next Step:** Frontend cleanups (firebase_service.dart)

**Backend Progress**: Steps 1-2 ✅ Backend now uses OTP only for verification.

**Estimated Time:** 15 mins

