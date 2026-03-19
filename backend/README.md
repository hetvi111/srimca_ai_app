# SRIMCA AI Backend

Python + MongoDB Atlas + Firebase Backend for SRIMCA AI Application

## Overview

This backend provides:
- **MongoDB Atlas Integration** - Cloud database that works 24/7 (even when laptop is disconnected)
- **Firebase Integration** - For verifying Firebase auth tokens from mobile app
- **JWT Authentication** - Secure API access
- **Role-based Access Control** - Different endpoints for admin/faculty/student

## Features

- User authentication (login/register)
- Notice management
- Assignment management
- Study materials management
- FAQ management
- User profile management

## Project Structure

```
backend/
├── .env.example          # Environment variables template
├── requirements.txt      # Python dependencies
├── config.py             # MongoDB Atlas & Firebase configuration
├── database.py           # Database connection helper
├── models.py             # Data models/schemas
├── firebase.py           # Firebase Admin SDK integration
├── auth.py               # Login/Register routes
├── app.py                # Main Flask application
└── routes/
    ├── __init__.py
    ├── notices.py        # Notice CRUD operations
    ├── assignments.py    # Assignment CRUD operations
    ├── materials.py      # Study materials CRUD
    ├── faqs.py          # FAQ operations
    └── users.py         # User management
```

## Setup Instructions

### 1. Prerequisites

- Python 3.8+
- MongoDB Atlas Account
- Firebase Project

### 2. Install Dependencies

```
bash
cd backend
pip install -r requirements.txt
```

### 3. Configure Environment Variables

Copy `.env.example` to `.env` and fill in your values:

```
bash
cp .env.example .env
```

Edit `.env` with your actual values from `.env.example`. **Important new vars:**

- **HF_TOKEN**: Get free from https://huggingface.co/settings/tokens (required for AI model downloads without rate limit warnings)
- All other vars (MongoDB, Firebase, JWT, etc.)

**Example .env structure shown in .env.example**

**Note:** HF_TOKEN eliminates "unauthenticated requests" warning from sentence-transformers (used in AI chat). Sign up at Hugging Face if needed.

### 4. MongoDB Atlas Setup

1. Create a MongoDB Atlas account at https://www.mongodb.com/cloud/atlas
2. Create a new cluster (free tier works)
3. Create a database user
4. Get the connection string (click "Connect" > "Connect your application")
5. Replace the connection string in `.env`

### 5. Firebase Setup

1. Go to Firebase Console https://console.firebase.google.com
2. Select your project (srimcaai)
3. Go to Project Settings > Service Accounts
4. Click "Generate new private key"
5. Copy the JSON content to get:
   - `private_key` (the key value)
   - `client_email` (the email value)
6. Update `.env` with these values

### 6. Run the Server

**Development:**
```
bash
cd backend
python app.py
```

The server will start at http://localhost:5000

**Production (using gunicorn):**
```
bash
gunicorn -w 4 -b 0.0.0.0:5000 app:application
```

## API Endpoints

### Authentication
- `POST /api/register` - Register new user
- `POST /api/login` - Login user
- `GET /api/verify` - Verify JWT token
- `POST /api/refresh` - Refresh JWT token
- `POST /api/change-password` - Change password

### Notices
- `GET /api/notices` - Get all notices
- `GET /api/notices/<id>` - Get single notice
- `POST /api/notices` - Create notice (auth required)
- `PUT /api/notices/<id>` - Update notice (auth required)
- `DELETE /api/notices/<id>` - Delete notice (auth required)

### Assignments
- `GET /api/assignments` - Get all assignments
- `GET /api/assignments/<id>` - Get single assignment
- `POST /api/assignments` - Create assignment (auth required)
- `PUT /api/assignments/<id>` - Update assignment (auth required)
- `DELETE /api/assignments/<id>` - Delete assignment (auth required)
- `POST /api/assignments/<id>/submit` - Submit assignment (auth required)

### Materials
- `GET /api/materials` - Get all materials
- `GET /api/materials/<id>` - Get single material
- `POST /api/materials` - Upload material (auth required)
- `PUT /api/materials/<id>` - Update material (auth required)
- `DELETE /api/materials/<id>` - Delete material (auth required)

### FAQs
- `GET /api/faqs` - Get all FAQs
- `GET /api/faqs/<id>` - Get single FAQ
- `POST /api/faqs` - Create FAQ (auth required)
- `PUT /api/faqs/<id>` - Update FAQ (auth required)
- `DELETE /api/faqs/<id>` - Delete FAQ (auth required)

### Users
- `GET /api/users/profile` - Get current user profile (auth required)
- `PUT /api/users/profile` - Update profile (auth required)
- `GET /api/users/<id>` - Get user by ID (auth required)
- `GET /api/users` - Get all users (admin only)

### Health Check
- `GET /health` - Check API and database health

## Flutter App Integration

Update the API base URL in your Flutter app (`lib/login_register_screen.dart`):

```
dart
// For production, use your deployed backend URL
const String kApiBaseUrl = 'https://your-backend-url.com';
```

## Deployment

### Render.com (Recommended for free hosting)

1. Push your code to GitHub
2. Create a new Web Service on Render
3. Set:
   - Build Command: `pip install -r backend/requirements.txt`
   - Start Command: `gunicorn -w 4 -b 0.0.0.0:$PORT backend.app:application`
4. Add environment variables in Render dashboard
5. Deploy!

### Railway

1. Connect GitHub repo to Railway
2. Add environment variables
3. Deploy!

## Troubleshooting

### MongoDB Connection Issues
- Check your connection string
- Make sure your IP is whitelisted in MongoDB Atlas
- Check network connectivity

### Firebase Issues
- Verify the private key is correct (contains `\n` for newlines)
- Check that the service account has proper permissions

### JWT Issues
- Make sure JWT_SECRET_KEY is set
- Check token expiration settings

## License

MIT License
