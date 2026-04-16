# Firebase Email OTP Integration TODO

## Status: 🚀 In Progress

### ✅ Step 1: Create TODO.md [COMPLETED]

### ✅ Step 2: Add OTP API helpers to api_service.dart [COMPLETED]
- Added `sendRegistrationOtp(email, [name])`
- Added `verifyRegistrationOtp(email, otp)`

### ✅ Step 3: Update registration_otp_page.dart [COMPLETED]
- Replaced Firebase PhoneAuth with backend email OTP calls
- Fixed UI text from phone to email
- Added resend cooldown (60s)
- Improved error states

### ✅ Step 4: Update login_register_screen.dart [COMPLETED]
- Pass `email` instead of `phoneNumber` to OTP page
- Removed phone country code validation for OTP
- Normalized email.toLowerCase()

### ⏳ Step 5: Test complete flow
```
1. Register → Send OTP button (backend /send-registration-otp)
2. Enter OTP → Verify (backend /verify-registration-otp)  
3. Complete → /register (creates MongoDB + Firebase user)
4. Check Firebase Console + email verification link
```

### ⏳ Step 6: Update TODO with results
- Mark completed steps
- Add testing notes
- Close task with attempt_completion

**Current Progress:** 4/6 completed



### ⏳ Step 4: Update login_register_screen.dart  
- Pass `email` instead of `phoneNumber` to OTP page
- Remove phone country code validation for OTP
- Normalize email.toLowerCase()

### ⏳ Step 5: Test complete flow
```
1. Register → Send OTP button (backend /send-registration-otp)
2. Enter OTP → Verify (backend /verify-registration-otp)  
3. Complete → /register (creates MongoDB + Firebase user)
4. Check Firebase Console + email verification link
```

### ⏳ Step 6: Update TODO with results
- Mark completed steps
- Add testing notes
- Close task with attempt_completion

**Current Progress:** 2/6 completed


### ⏳ Step 3: Update registration_otp_page.dart
- Replace Firebase PhoneAuth with backend email OTP calls
- Fix UI text from phone to email
- Add resend cooldown (60s)
- Improve error states

### ⏳ Step 4: Update login_register_screen.dart  
- Pass `email` instead of `phoneNumber` to OTP page
- Remove phone country code validation for OTP
- Normalize email.toLowerCase()

### ⏳ Step 5: Test complete flow
```
1. Register → Send OTP button (backend /send-registration-otp)
2. Enter OTP → Verify (backend /verify-registration-otp)  
3. Complete → /register (creates MongoDB + Firebase user)
4. Check Firebase Console + email verification link
```

### ⏳ Step 6: Update TODO with results
- Mark completed steps
- Add testing notes
- Close task with attempt_completion

**Current Progress:** 1/6 completed
**Estimated Time:** 15 mins
