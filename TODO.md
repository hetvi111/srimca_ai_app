# Password Reset Flow Implementation Plan

## 1. Create TODO.md ✅
## 2. Update Frontend List View (admin_password_requests_page.dart)
- Show enrollmentNumber in subtitle for students (already fetched in API)
- Show email for faculty/other
## 3. Update ApiService.adminResetPassword()
- Add newPassword param to body
## 4. Major UI Change: admin_password_reset_detail_page.dart
- Remove verification controllers/fields
- Add newPassword & confirmPassword TextFields (obscureText: true)
- Display enrollment/email as label (read-only)
- Validate passwords match, length >=6
- On submit: call API with new_password, show success Snackbar, pop(true)
## 5. Backend Update: backend/routes/users.py reset_password_admin()
- If 'new_password' in body: use it (validate length), hash with bcrypt
- Remove verification logic or make optional
- Update request status to 'reset', return success (no new_password returned)
## 6. Test Flow
- Submit forgot pw as student/faculty
- Admin view requests (see enrollment/email)
- Click request → set new pw + confirm → submit → success → list refresh


