# SRIMCA AI

Flutter app with Firebase (Auth + Firestore) and a Python backend API.

## Goal

Use Firebase for free live hosting and avoid Render-specific URLs.

## Free Hosting Setup (Firebase)

### 1) Install tools

```bash
npm install -g firebase-tools
firebase login
```

### 2) Select Firebase project

```bash
firebase use srimcaai
```

If this is your first time setting up Hosting, also run:

```bash
firebase init hosting
```

### 3) Build Flutter web app for this project

```bash
flutter build web --release
```

Note: `firebase.json` is already configured to deploy `build/web`.

### 4) Deploy to Firebase Hosting (free tier)

```bash
firebase deploy --only hosting
```

After deploy, your live app URL will be:
- `https://srimcaai.web.app`
- `https://srimcaai.firebaseapp.com`

## Data Store (Firebase Firestore)

Firebase client code is already present in:
- `lib/firebase_service.dart`

Collections currently used:
- `users`
- `notices`
- `assignments`
- `materials`
- `faqs`

## Backend URL Configuration (no Render hardcoding)

API base URL now comes from compile-time define:
- `API_PROD_URL`

Example:

```bash
flutter run --dart-define=API_PROD_URL=https://your-backend-url
```

For visitor QR/register link:

```bash
flutter run --dart-define=VISITOR_REG_URL=https://srimcaai.web.app/register
```

## Local Development

Backend:

```bash
cd backend
pip install -r requirements.txt
python app.py
```

Flutter:

```bash
flutter pub get
flutter run
```
