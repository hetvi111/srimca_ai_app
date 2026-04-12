# 🚀 Network Timeout Fix - Render Sleep Issue

## Status: ⏳ In Progress

## Steps:

- [x] **1. Increase Flutter timeouts** from 30s → 60s in `lib/api_service.dart`
  - Update all `.timeout(const Duration(seconds: 30))` → `60`

- [x] **2. Add `/api/health` endpoint** in `backend/app.py`

- [ ] **3. Test locally**
  ```
  cd backend
  python app.py
  # Test: http://localhost:5000/health
  # Test: http://localhost:5000/api/health
  ```

- [ ] **4. Test Flutter app**
  ```
  flutter run
  ```

- [ ] **5. Deploy fixes** (git push → Render auto-deploys)

- [ ] **6. Railway Migration (Optional Permanent Fix)**
  - Create Railway account
  - Connect GitHub repo
  - Deploy backend
  - Update `kProductionUrl`

- [ ] **7. Setup monitoring** (UptimeRobot ping `/health` every 5min)

## Commands Ready:
```bash
# Local test
cd backend && python app.py

# Flutter test  
flutter run

# Deploy
git add . && git commit -m \"fix: increase timeout to 60s + add api/health\" && git push
```

**Current Step: 3/7 - Test local backend & Flutter. Fixes ready for deploy!**
