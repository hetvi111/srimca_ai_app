# SRIMCA AI Visitor Features Implementation TODO

## Current Status
- [x] Authentication (register/login/logout for visitors)
- [x] AI Chat (24/7 GPT + RAG)
- [x] Basic Profile View
- [ ] Dynamic QR Visitor Pass + History

## Step-by-Step Plan (Backend First)

### Phase 1: Backend (visitor.py + DB)
- [x] 1. Add VISITOR_LOGS to database.py
- [x] 2. Create VisitorLogModel in models.py
- [x] 3. Create backend/routes/visitor.py with:
  | Endpoint | Method | Auth | Desc |
  |----------|--------|------|------|
  | /api/visitor/profile/<id> | GET/PATCH | visitor/admin | Get/update profile |
  | /api/visitor/history/<id> | GET | visitor/admin | Get visit logs |
  | /api/visitor/qr/<id> | GET | visitor | Generate dynamic QR PNG base64 |
  | /api/visitor/checkin | POST | optional (token) | Log check-in from QR scan |
- [x] 4. Register visitor_bp in app.py
- [x] 5. Update generate_visitor_qr.py for dynamic

### Phase 2: Flutter APIs + UI
- [ ] 6. lib/api_service.dart: Add getVisitorProfile(id), updateVisitorProfile(id,data), getVisitorHistory(id), generateVisitorQR(id), checkinVisitor(token)
- [ ] 7. lib/visitor_profile_page.dart: Real API fetch history/profile, update form → API, "Generate QR Pass" button (shows QR), "Check-in Now" button
- [ ] 8. lib/VisitorHomePage.dart: Add QR quick action → profile QR
- [ ] 9. lib/admin_main_dashboard.dart: Add "Visitor QR Stats" card (total visitors/logs)

### Phase 3: Polish + Test
- [ ] 10. Add sample visitor_logs via script
- [ ] 11. Test full flow: Register → Login → Profile → QR → Check-in → History
- [ ] 12. Flutter lint + backend test commands
- [ ] 13. Update README.md with new features

## Commands
```
# Backend deps
cd backend && pip install qrcode[pil] pillow

# Regenerate static QR (gate)
cd backend && python generate_visitor_qr.py

# Test QR scan
curl -X POST http://localhost:5000/api/visitor/checkin -d 'token=xyz'

# Flutter test
flutter run
```

## Completion Criteria
- [ ] End-to-end visitor flow works
- [ ] QR generates/displays correctly
- [ ] History shows real check-ins
- [ ] Admin JWT protected
- [ ] attempt_completion

