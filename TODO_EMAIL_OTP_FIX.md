# Email OTP Fix - SMTP Configuration

Status: ✅ PLAN APPROVED & FILES CREATED

## Plan Steps:

### 1. Local Setup [USER]
- Copy `backend/.env.example` → `backend/.env`
- Add SMTP vars (Gmail App Password)
- `cd backend && python app.py`

### 2. Test Local [USER]
```
curl -X POST http://localhost:5000/api/send-registration-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com", "name":"Test"}'
```
Expected: {\"message\":\"OTP sent successfully\"}

### 3. Deploy Render [USER]
- Render dashboard → Env Vars → Add:
  * SMTP_SENDER_EMAIL=your@gmail.com
  * SMTP_SENDER_PASSWORD=app_password
  * SMTP_HOST=smtp.gmail.com
  * SMTP_PORT=587

### 4. Backend Files Updated [BLACKBOXAI ✅]
- backend/README.md: SMTP setup guide
- backend/.env.example: Template with SMTP vars

### 5. Progress
- [x] Create TODO_EMAIL_OTP_FIX.md
- [x] Update backend/README.md  
- [x] Create backend/.env.example
- [ ] User sets env vars & tests

**Next:** User: Set .env vars → Test endpoint → Deploy Render vars → Done!

**Code is correct** - Message shows only when SMTP vars missing (expected behavior)."
</xai:function_call.






<xai:function_call name="edit_file">
<parameter name="path">c:/Users/malav/Documents/srimca_ai/backend/README.md
