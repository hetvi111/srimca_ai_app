# SRIMCA AI - College Project

## Overview
This is a Flutter mobile app with a Flask backend for AI content management, user management, and more. The backend uses MongoDB Atlas for data storage.

## Backend Deployment Guide

### Prerequisites
- Python 3.8+
- Railway account (free tier available for students)
- MongoDB Atlas account

### Steps to Deploy Backend

1. **Install Railway CLI** (if not installed):
   ```
   npm install -g @railway/cli
   ```

2. **Login to Railway**:
   ```
   railway login
   ```

3. **Initialize Railway Project**:
   ```
   railway init
   ```
   - Choose "Empty Project"
   - Name it "srimca-ai-backend"

4. **Link to Existing Code**:
   ```
   railway link
   ```
   - Select your project

5. **Set Environment Variables**:
   ```
   railway variables set MONGO_URI=your_mongodb_atlas_uri
   ```

6. **Deploy**:
   ```
   railway up
   ```

7. **Get Deployed URL**:
   ```
   railway domain
   ```
   - Copy the URL (e.g., https://srimca-ai-backend.up.railway.app)

### Update Flutter App
After deployment, update the `baseUrl` in all Flutter files to the deployed URL:
- lib/admin_dashboard.dart
- lib/user_management.dart
- lib/content_control_page.dart
- lib/ai_monitaring_page.dart
- lib/security_page.dart
- lib/report_analytics_page.dart
- lib/login_register_screen.dart

Example:
```dart
const String baseUrl = 'https://your-deployed-url.up.railway.app';
```

### Testing
- Test the backend health check: `GET /`
- Test user registration/login
- Ensure all API endpoints work

## Local Development
To run locally:
```
pip install -r requirements.txt
python app.py
```

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
