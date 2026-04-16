# SRIMCA AI - Render to Firebase/Railway Migration TODO

Status: Backend → Railway, Frontend → Firebase Hosting, MongoDB unchanged
Date: $(date)

## Completed: 0/8

### 1. ✅ GitHub Repo Ready - Pushed to branch blackboxai/fix-backend-import-error
### 9. [ ] Add FlutterFire Config Step
   - FlutterFire CLI running
   - Select platforms (web ✔) Enter
   - main.dart fixed for firebase_options.dart
   - flutter clean & flutter pub get & flutter build web & firebase deploy --only hosting
   - Live: https://srimcaai.web.app
   ```bash
   git commit -m "Migration prep" ^& git push
   ```
   - Repo: https://github.com/hetvi111/srimca_ai_app.git
   ```bash
   git remote -v
   ```
   - If no origin, create GitHub repo, git remote add origin https://github.com/username/srimca-ai.git
   - git push -u origin main

### 2. [ ] Deploy Backend to Railway
   - Go to https://railway.app → New Project → Deploy from GitHub
   - Select repo
   - Set env vars:
     * MONGODB_URI = mongodb+srv://n8n:n8nconnection@cluster0.guplsjx.mongodb.net/?retryWrites=true&w=majority (or your Atlas URI)
     * PORT=8080 (auto)
   - **Record new backend URL** (e.g., https://your-project.up.railway.app)

### 3. [ ] Update Flutter API Base URL
   - Edit lib/api_service.dart: replace Render URL with Railway URL
   - flutter pub get

### 4. [ ] Clean & Build Flutter Web
   ```bash
   flutter clean
   flutter pub get
   flutter build web
   ```

### 5. [ ] Verify Firebase Setup
   ```bash
   firebase projects:list
   firebase use
   ```

### 6. [ ] Deploy Frontend to Firebase
   ```bash
   firebase deploy --only hosting
   ```
   - Live at https://srimcaai.web.app or https://srimcaai.firebaseapp.com

### 7. [ ] Full Stack Test
   - Visit Firebase URL
   - Test login, AI chat (askAI), notices, admin dashboard
   - Check browser console for API errors

### 8. [ ] Cleanup & Monitor
   - Delete Render dashboard service
   - Update README.md with new URLs
   - Monitor: Firebase Console + Railway dashboard
   - Railway free tier limits: check usage

## Commands Ready to Copy-Paste

**Build & Deploy Frontend:**
```bash
flutter clean && flutter pub get && flutter build web && firebase deploy --only hosting
```

**Local Test:**
```bash
flutter run -d chrome --web-hostname localhost --web-port 8080
```

## New Architecture
```
Frontend: Firebase Hosting (CDN fast)
     ↓
Backend: Railway (no sleep, scales)
     ↓
DB: MongoDB Atlas (unchanged)
```

**Viva Points:**
- Firebase Hosting: static Flutter web
- Railway: Dynamic Flask API
- MongoDB Atlas: Reliable NoSQL

✅ Migration complete = No more Render failures!
