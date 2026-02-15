# SRIMCA AI - College Project

## Overview
This is a Flutter mobile app with a Flask backend for AI content management, user management, and more. The backend uses MongoDB Atlas for data storage.

## Backend Deployment Guide

### Option 1: Deploy to Render (Recommended)

#### Prerequisites
- Python 3.8+
- GitHub account
- Render account (free tier available)
- MongoDB Atlas account

#### Steps to Deploy Backend to Render

1. **Push Your Flask Project to GitHub**:
   - Create a new GitHub repository
   - Push all files including: `app.py`, `requirements.txt`, `Procfile`, `render.yaml`, `runtime.txt`

2. **Create a New Web Service on Render**:
   - Go to [Render Dashboard](https://dashboard.render.com)
   - Click "New" → "Web Service"
   - Connect your GitHub account and select your repository

3. **Configure the Web Service**:
   - Name: `srimca-ai-backend`
   - Runtime: Python
   - Build Command: `pip install -r requirements.txt`
   - Start Command: `python app.py`

4. **Set Environment Variables**:
   - Click "Advanced" → "Add Environment Variables`
   - Add the following:
     - `MONGODB_URI` = Your MongoDB Atlas connection string (e.g., `mongodb+srv://username:password@cluster.mongodb.net/?retryWrites=true&w=majority`)
     - `DB_NAME` = `srimca_ai`
     - `PORT` = `10000` (Render will override this, but it's fine)

5. **Deploy the Service**:
   - Click "Create Web Service"
   - Wait for the build to complete
   - Once deployed, you'll get your API URL (e.g., `https://srimca-ai-backend.onrender.com`)

---

### Option 2: Deploy to Railway

#### Prerequisites
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
- lib/ai_monitoring_page.dart
- lib/security_page.dart
- lib/reports_analytics_page.dart
- lib/login_register_screen.dart

Example:
```dart
const String baseUrl = 'https://srimca-ai-backend.onrender.com';
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

The backend will run on http://localhost:5000

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
