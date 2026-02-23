"""
SRIMCA AI Backend - Main Flask Application
Flask + MongoDB Atlas + Firebase Integration
"""

from flask import Flask, jsonify, request, send_file
from flask_cors import CORS
import os
import sys
import qrcode
import io

# Add backend directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from config import get_config, config_by_name
from database import connect_to_mongodb, initialize_indexes, health_check, close_mongodb_connection
from firebase import initialize_firebase
from auth import auth_bp

# Import route blueprints
try:
    from routes.notices import notices_bp
    from routes.assignments import assignments_bp
    from routes.materials import materials_bp
    from routes.faqs import faqs_bp
    from routes.users import users_bp
    from routes.notifications import notifications_bp
    from routes.admin import admin_bp
    ROUTES_AVAILABLE = True
except ImportError as e:
    print(f"Warning: Some routes could not be imported: {e}")
    ROUTES_AVAILABLE = False


def create_app(config_name=None):
    """
    Create and configure the Flask application
    """
    # Initialize Flask
    app = Flask(__name__)
    
    # Load configuration
    if config_name:
        config = config_by_name.get(config_name, DevelopmentConfig)
    else:
        config = get_config()
    
    app.config['SECRET_KEY'] = config.JWT_SECRET_KEY
    app.config['DEBUG'] = config.FLASK_DEBUG
    
    # Configure CORS
    cors_origins = config.CORS_ORIGINS.split(',') if config.CORS_ORIGINS != '*' else ['*']
    CORS(app, origins=cors_origins, supports_credentials=True)
    
    # Register blueprints
    app.register_blueprint(auth_bp)
    
    if ROUTES_AVAILABLE:
        try:
            app.register_blueprint(notices_bp)
            app.register_blueprint(assignments_bp)
            app.register_blueprint(materials_bp)
            app.register_blueprint(faqs_bp)
            app.register_blueprint(users_bp)
            app.register_blueprint(notifications_bp)
            app.register_blueprint(admin_bp)
        except Exception as e:
            print(f"Warning: Could not register some blueprints: {e}")
    
    # Health check endpoint
    @app.route('/health', methods=['GET'])
    def health():
        """Health check endpoint"""
        mongodb_status, mongodb_message = health_check()
        
        return jsonify({
            'status': 'healthy' if mongodb_status else 'degraded',
            'mongodb': {
                'connected': mongodb_status,
                'message': mongodb_message
            },
            'firebase': {
                'enabled': initialize_firebase() is not None
            }
        }), 200 if mongodb_status else 503
    
    # Root endpoint
    @app.route('/', methods=['GET'])
    def root():
        """Root endpoint"""
        return jsonify({
            'name': 'SRIMCA AI Backend',
            'version': '1.0.0',
            'status': 'running',
            'endpoints': {
                'auth': '/api',
                'notices': '/api/notices',
                'assignments': '/api/assignments',
                'materials': '/api/materials',
                'faqs': '/api/faqs',
                'users': '/api/users',
                'health': '/health'
            }
        }), 200
    
    # Simple AI Chat endpoint - direct text file based
    @app.route('/api/ai/chat', methods=['POST'])
    def ai_chat():
        """Simple AI Chat endpoint using text file knowledge base"""
        try:
            data = request.get_json()
            if not data or 'question' not in data:
                return jsonify({'error': 'Question is required'}), 400
            
            question = data['question'].strip().lower()
            if not question:
                return jsonify({'error': 'Question cannot be empty'}), 400
            
            # Load knowledge base directly
            import glob
            data_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'srimca', 'data')
            all_lines = []
            
            for f in glob.glob(f"{data_dir}/*.txt"):
                with open(f, "r", encoding="utf-8") as file:
                    all_lines.extend([l.strip() for l in file.read().split('\n') if l.strip()])
            
            # Search for matching answer
            answer = None
            
            # Keywords to look for
            keywords_map = {
                'full name': ['full name'],
                'located': ['located', 'where'],
                'university': ['university', 'uka tarsadia', 'affiliated'],
                'vision': ['vision'],
                'mission': ['mission'],
                'courses': ['courses', 'programme', 'programs', 'offers'],
                'computer': ['computer', 'computers'],
                'wifi': ['wi-fi', 'wifi', 'internet'],
                'library': ['library', 'books', 'journals'],
                'mca': ['mca', 'master'],
                'mba': ['mba', 'management'],
                'started': ['started', 'year'],
            }
            
            # Check for exact question matches
            if 'full name' in question:
                for line in all_lines:
                    if 'full name' in line.lower():
                        answer = line
                        break
            elif 'name' in question:
                for line in all_lines:
                    if line.lower().startswith('srimca'):
                        answer = line
                        break
            elif 'located' in question or 'where' in question or 'address' in question:
                for line in all_lines:
                    if 'located' in line.lower():
                        answer = line
                        break
            elif 'university' in question or 'affiliated' in question:
                for line in all_lines:
                    if 'university' in line.lower() or 'uka tarsadia' in line.lower():
                        answer = line
                        break
            elif 'vision' in question:
                for line in all_lines:
                    if 'vision' in line.lower():
                        answer = line
                        break
            elif 'mission' in question:
                for line in all_lines:
                    if 'mission' in line.lower():
                        answer = line
                        break
            elif 'course' in question or 'program' in question:
                for line in all_lines:
                    if 'offers' in line.lower():
                        answer = line
                        break
            elif 'computer' in question or 'wifi' in question or 'internet' in question:
                for line in all_lines:
                    if 'computer' in line.lower() or 'wi-fi' in line.lower():
                        answer = line
                        break
            elif 'library' in question or 'book' in question:
                for line in all_lines:
                    if 'library' in line.lower():
                        answer = line
                        break
            elif 'timetable' in question or 'schedule' in question or 'monday' in question or 'tuesday' in question:
                # Look for timetable entries
                for line in all_lines:
                    if 'monday' in line.lower() or 'tuesday' in line.lower():
                        if 'semester' in line.lower():
                            answer = line
                            break
            
            # If no specific match, try keyword scoring
            if not answer:
                stop_words = {'what', 'is', 'are', 'the', 'a', 'an', 'of', 'for', 'in', 'on', 'at', 'to', 'do', 'does', 'can', 'you', 'i', 'we', 'they', 'srimca', 'mca', 'mba', 'my', 'me', 'about', 'tell', 'show', 'get', 'your'}
                keywords = [w for w in question.split() if w not in stop_words and len(w) > 2]
                
                best_line = None
                best_score = 0
                
                for line in all_lines:
                    score = sum(1 for k in keywords if k in line.lower())
                    if score > best_score:
                        best_score = score
                        best_line = line
                
                if best_score >= 1:
                    answer = best_line
            
            if not answer:
                answer = "I don't have specific information about that. You can ask me about:\n- College name and location\n- Courses offered (MCA, MBA)\n- University affiliation\n- Vision and mission\n- Timetable/schedule\n- Facilities (library, computers)"
            
            return jsonify({
                'question': question,
                'answer': answer,
                'status': 'success'
            }), 200
            
        except Exception as e:
            print(f"AI Chat Error: {e}")
            import traceback
            traceback.print_exc()
            return jsonify({'error': str(e)}), 500
    
    # QR Code generation endpoint
    @app.route('/generate-qr', methods=['GET'])
    def generate_qr():
        """Generate QR code for visitor registration"""
        registration_url = "https://srimca-ai-app.onrender.com/register"
        
        qr = qrcode.make(registration_url)
        img_io = io.BytesIO()
        qr.save(img_io, 'PNG')
        img_io.seek(0)
        
        return send_file(img_io, mimetype='image/png')
    
    # Visitor registration page (web-based)
    @app.route('/register', methods=['GET'])
    def visitor_register_page():
        """Serve the visitor registration web page"""
        return '''
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Registration - SRIMCA</title>
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body {
                    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    min-height: 100vh;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    padding: 20px;
                }
                .container {
                    background: white;
                    border-radius: 20px;
                    box-shadow: 0 20px 60px rgba(0,0,0,0.3);
                    padding: 40px;
                    max-width: 550px;
                    width: 100%;
                }
                h1 {
                    color: #333;
                    text-align: center;
                    margin-bottom: 10px;
                    font-size: 28px;
                }
                .subtitle {
                    text-align: center;
                    color: #666;
                    margin-bottom: 30px;
                }
                .form-group {
                    margin-bottom: 18px;
                }
                label {
                    display: block;
                    color: #333;
                    margin-bottom: 6px;
                    font-weight: 600;
                    font-size: 14px;
                }
                input, select {
                    width: 100%;
                    padding: 12px;
                    border: 2px solid #e0e0e0;
                    border-radius: 10px;
                    font-size: 15px;
                    transition: border-color 0.3s;
                }
                input:focus, select:focus {
                    outline: none;
                    border-color: #667eea;
                }
                .row {
                    display: grid;
                    grid-template-columns: 1fr 1fr;
                    gap: 15px;
                }
                button {
                    width: 100%;
                    padding: 14px;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    border: none;
                    border-radius: 10px;
                    font-size: 16px;
                    font-weight: 600;
                    cursor: pointer;
                    transition: transform 0.2s, box-shadow 0.2s;
                    margin-top: 10px;
                }
                button:hover {
                    transform: translateY(-2px);
                    box-shadow: 0 10px 30px rgba(102, 126, 234, 0.4);
                }
                button:disabled {
                    background: #ccc;
                    cursor: not-allowed;
                    transform: none;
                }
                .message {
                    padding: 12px;
                    border-radius: 10px;
                    margin-bottom: 20px;
                    text-align: center;
                    display: none;
                }
                .message.success {
                    background: #d4edda;
                    color: #155724;
                    display: block;
                }
                .message.error {
                    background: #f8d7da;
                    color: #721c24;
                    display: block;
                }
                .login-link {
                    text-align: center;
                    margin-top: 20px;
                    color: #666;
                }
                .login-link a {
                    color: #667eea;
                    text-decoration: none;
                    font-weight: 600;
                }
                .login-link a:hover {
                    text-decoration: underline;
                }
                .logo {
                    text-align: center;
                    margin-bottom: 20px;
                }
                .logo h2 {
                    color: #667eea;
                    font-size: 24px;
                }
                .hidden { display: none; }
                .info-text {
                    font-size: 12px;
                    color: #888;
                    margin-top: 4px;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="logo">
                    <h2>🎓 SRIMCA</h2>
                </div>
                <h1>Visitor Registration</h1>
                <p class="subtitle">Welcome to SRIMCA College</p>
                
                <div id="message" class="message"></div>
                
                <form id="registrationForm">
                    <input type="hidden" id="role" name="role" value="visitor">
                    
                    <!-- Common Fields -->
                    <div class="form-group">
                        <label for="name">Full Name *</label>
                        <input type="text" id="name" name="name" required placeholder="Enter your full name">
                    </div>
                    
                    <div class="form-group">
                        <label for="email">Email ID *</label>
                        <input type="email" id="email" name="email" required placeholder="Enter your email address">
                    </div>
                    
                    <div class="form-group">
                        <label for="mobile">Mobile Number *</label>
                        <input type="tel" id="mobile" name="mobile" required placeholder="Enter your mobile number" pattern="[0-9]{10,}">
                    </div>
                    
                    <!-- Visitor-specific Fields (always visible) -->
                    <div id="visitorFields">
                        <div class="form-group">
                            <label for="purpose">Purpose of Visit *</label>
                            <select id="purpose" name="purpose" required>
                                <option value="">Select purpose</option>
                                <option value="admission">Admission Inquiry</option>
                                <option value="placement">Placement/Recruitment</option>
                                <option value="meeting">Meeting with Faculty</option>
                                <option value="event">College Event</option>
                                <option value="tour">Campus Tour</option>
                                <option value="other">Other</option>
                            </select>
                            <div class="info-text">Used for security tracking</div>
                        </div>
                    </div>
                    
                    <div class="row">
                        <div class="form-group">
                            <label for="password">Password *</label>
                            <input type="password" id="password" name="password" required placeholder="Create password" minlength="6">
                        </div>
                        
                        <div class="form-group">
                            <label for="confirmPassword">Confirm Password *</label>
                            <input type="password" id="confirmPassword" name="confirmPassword" required placeholder="Confirm password">
                        </div>
                    </div>
                    
                    <button type="submit" id="submitBtn">Register</button>
                </form>
                
                <p class="login-link">
                    Already registered? <a href="/login">Login here</a>
                </p>
            </div>
            
            <script>
                // Simplified for visitor-only registration
                document.getElementById('registrationForm').addEventListener('submit', async function(e) {
                    e.preventDefault();
                    
                    const password = document.getElementById('password').value;
                    const confirmPassword = document.getElementById('confirmPassword').value;
                    
                    if (password !== confirmPassword) {
                        showMessage('Passwords do not match', 'error');
                        return;
                    }
                    
                    const submitBtn = document.getElementById('submitBtn');
                    const messageDiv = document.getElementById('message');
                    
                    submitBtn.disabled = true;
                    submitBtn.textContent = 'Registering...';
                    messageDiv.className = 'message';
                    messageDiv.style.display = 'none';
                    
                    const formData = {
                        name: document.getElementById('name').value,
                        email: document.getElementById('email').value,
                        mobile: document.getElementById('mobile').value,
                        password: password,
                        role: currentRole
                    };
                    
                    // Add role-specific fields
                    if (currentRole === 'student') {
                        formData.enrollment = document.getElementById('enrollment').value;
                        formData.dob = document.getElementById('dob').value;
                        formData.semester = document.getElementById('semester').value;
                        formData.department = document.getElementById('department').value;
                    } else {
                        formData.purpose = document.getElementById('purpose').value;
                    }
                    
                    try {
                        const response = await fetch('/api/register', {
                            method: 'POST',
                            headers: {
                                'Content-Type': 'application/json'
                            },
                            body: JSON.stringify(formData)
                        });
                        
                        const data = await response.json();
                        
                        if (response.ok) {
                            showMessage('Registration successful! Redirecting to login...', 'success');
                            document.getElementById('registrationForm').reset();
                            setTimeout(() => {
                                window.location.href = '/login';
                            }, 2000);
                        } else {
                            showMessage(data.error || 'Registration failed', 'error');
                        }
                    } catch (error) {
                        showMessage('Network error. Please try again.', 'error');
                    }
                    
                    submitBtn.disabled = false;
                    submitBtn.textContent = 'Register';
                });
                
                function showMessage(text, type) {
                    const messageDiv = document.getElementById('message');
                    messageDiv.textContent = text;
                    messageDiv.className = 'message ' + type;
                }
                
                // Initialize role
                selectRole('student');
            </script>
        </body>
        </html>
        '''
    
    # Visitor login page
    @app.route('/login', methods=['GET'])
    def visitor_login_page():
        """Serve the visitor login web page"""
        return '''
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Visitor Login - SRIMCA</title>
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body {
                    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    min-height: 100vh;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    padding: 20px;
                }
                .container {
                    background: white;
                    border-radius: 20px;
                    box-shadow: 0 20px 60px rgba(0,0,0,0.3);
                    padding: 40px;
                    max-width: 450px;
                    width: 100%;
                }
                h1 {
                    color: #333;
                    text-align: center;
                    margin-bottom: 10px;
                    font-size: 28px;
                }
                .subtitle {
                    text-align: center;
                    color: #666;
                    margin-bottom: 30px;
                }
                .form-group {
                    margin-bottom: 20px;
                }
                label {
                    display: block;
                    color: #333;
                    margin-bottom: 8px;
                    font-weight: 600;
                }
                input {
                    width: 100%;
                    padding: 14px;
                    border: 2px solid #e0e0e0;
                    border-radius: 10px;
                    font-size: 16px;
                    transition: border-color 0.3s;
                }
                input:focus {
                    outline: none;
                    border-color: #667eea;
                }
                button {
                    width: 100%;
                    padding: 16px;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    border: none;
                    border-radius: 10px;
                    font-size: 18px;
                    font-weight: 600;
                    cursor: pointer;
                    transition: transform 0.2s, box-shadow 0.2s;
                }
                button:hover {
                    transform: translateY(-2px);
                    box-shadow: 0 10px 30px rgba(102, 126, 234, 0.4);
                }
                button:disabled {
                    background: #ccc;
                    cursor: not-allowed;
                    transform: none;
                }
                .message {
                    padding: 15px;
                    border-radius: 10px;
                    margin-bottom: 20px;
                    text-align: center;
                    display: none;
                }
                .message.success {
                    background: #d4edda;
                    color: #155724;
                    display: block;
                }
                .message.error {
                    background: #f8d7da;
                    color: #721c24;
                    display: block;
                }
                .register-link {
                    text-align: center;
                    margin-top: 20px;
                    color: #666;
                }
                .register-link a {
                    color: #667eea;
                    text-decoration: none;
                    font-weight: 600;
                }
                .register-link a:hover {
                    text-decoration: underline;
                }
                .logo {
                    text-align: center;
                    margin-bottom: 20px;
                }
                .logo h2 {
                    color: #667eea;
                    font-size: 24px;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="logo">
                    <h2>🎓 SRIMCA</h2>
                </div>
                <h1>Visitor Login</h1>
                <p class="subtitle">Welcome back to SRIMCA College</p>
                
                <div id="message" class="message"></div>
                
                <form id="loginForm">
                    <div class="form-group">
                        <label for="email">Email Address</label>
                        <input type="email" id="email" name="email" required placeholder="Enter your email address">
                    </div>
                    
                    <div class="form-group">
                        <label for="password">Password</label>
                        <input type="password" id="password" name="password" required placeholder="Enter your password">
                    </div>
                    
                    <button type="submit" id="submitBtn">Login</button>
                </form>
                
                <p class="register-link">
                    New visitor? <a href="/register">Register here</a>
                </p>
            </div>
            
            <script>
                document.getElementById('loginForm').addEventListener('submit', async function(e) {
                    e.preventDefault();
                    
                    const submitBtn = document.getElementById('submitBtn');
                    const messageDiv = document.getElementById('message');
                    
                    submitBtn.disabled = true;
                    submitBtn.textContent = 'Logging in...';
                    messageDiv.className = 'message';
                    messageDiv.style.display = 'none';
                    
                    const formData = {
                        email: document.getElementById('email').value,
                        password: document.getElementById('password').value
                    };
                    
                    try {
                        const response = await fetch('/api/login', {
                            method: 'POST',
                            headers: {
                                'Content-Type': 'application/json'
                            },
                            body: JSON.stringify(formData)
                        });
                        
                        const data = await response.json();
                        
                        if (response.ok) {
                            localStorage.setItem('token', data.token);
                            localStorage.setItem('user', JSON.stringify(data.user));
                            messageDiv.textContent = 'Login successful! Redirecting...';
                            messageDiv.className = 'message success';
                            setTimeout(() => {
                                window.location.href = '/visitor-dashboard';
                            }, 1000);
                        } else {
                            messageDiv.textContent = data.error || 'Invalid credentials';
                            messageDiv.className = 'message error';
                        }
                    } catch (error) {
                        messageDiv.textContent = 'Network error. Please try again.';
                        messageDiv.className = 'message error';
                    }
                    
                    submitBtn.disabled = false;
                    submitBtn.textContent = 'Login';
                });
            </script>
        </body>
        </html>
        '''
    
    # Visitor dashboard page
    @app.route('/visitor-dashboard', methods=['GET'])
    def visitor_dashboard():
        """Serve the visitor dashboard web page"""
        return '''
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Visitor Dashboard - SRIMCA</title>
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body {
                    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                    background: #f5f7fa;
                    min-height: 100vh;
                }
                .header {
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    padding: 20px 40px;
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                }
                .header h1 { font-size: 24px; }
                .logout-btn {
                    background: rgba(255,255,255,0.2);
                    color: white;
                    border: none;
                    padding: 10px 20px;
                    border-radius: 8px;
                    cursor: pointer;
                    font-size: 14px;
                }
                .logout-btn:hover { background: rgba(255,255,255,0.3); }
                .container {
                    max-width: 1200px;
                    margin: 0 auto;
                    padding: 40px 20px;
                }
                .welcome {
                    background: white;
                    border-radius: 15px;
                    padding: 30px;
                    margin-bottom: 30px;
                    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                }
                .welcome h2 { color: #333; margin-bottom: 10px; }
                .welcome p { color: #666; }
                .grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
                    gap: 20px;
                }
                .card {
                    background: white;
                    border-radius: 15px;
                    padding: 30px;
                    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                    cursor: pointer;
                    transition: transform 0.2s, box-shadow 0.2s;
                }
                .card:hover {
                    transform: translateY(-5px);
                    box-shadow: 0 5px 20px rgba(0,0,0,0.15);
                }
                .card h3 { color: #333; margin-bottom: 15px; font-size: 20px; }
                .card p { color: #666; line-height: 1.6; }
                .card-icon {
                    font-size: 40px;
                    margin-bottom: 15px;
                }
                .chat-container {
                    display: none;
                    position: fixed;
                    bottom: 20px;
                    right: 20px;
                    width: 400px;
                    height: 500px;
                    background: white;
                    border-radius: 15px;
                    box-shadow: 0 5px 30px rgba(0,0,0,0.2);
                    flex-direction: column;
                }
                .chat-container.active { display: flex; }
                .chat-header {
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    padding: 15px 20px;
                    border-radius: 15px 15px 0 0;
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                }
                .chat-close {
                    background: none;
                    border: none;
                    color: white;
                    font-size: 24px;
                    cursor: pointer;
                }
                .chat-messages {
                    flex: 1;
                    padding: 20px;
                    overflow-y: auto;
                }
                .message {
                    margin-bottom: 15px;
                    padding: 12px 15px;
                    border-radius: 15px;
                    max-width: 80%;
                }
                .message.bot {
                    background: #f0f0f0;
                    color: #333;
                    margin-right: auto;
                }
                .message.user {
                    background: #667eea;
                    color: white;
                    margin-left: auto;
                }
                .chat-input {
                    padding: 15px;
                    border-top: 1px solid #eee;
                    display: flex;
                    gap: 10px;
                }
                .chat-input input {
                    flex: 1;
                    padding: 12px;
                    border: 1px solid #ddd;
                    border-radius: 8px;
                    font-size: 14px;
                }
                .chat-input button {
                    padding: 12px 20px;
                    background: #667eea;
                    color: white;
                    border: none;
                    border-radius: 8px;
                    cursor: pointer;
                }
                .chat-input button:hover { background: #5568d3; }
                .profile-card {
                    background: white;
                    border-radius: 15px;
                    padding: 30px;
                    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                }
                .profile-card h3 { color: #333; margin-bottom: 20px; }
                .profile-item {
                    display: flex;
                    padding: 15px 0;
                    border-bottom: 1px solid #eee;
                }
                .profile-item:last-child { border-bottom: none; }
                .profile-label {
                    font-weight: 600;
                    color: #666;
                    width: 150px;
                }
                .profile-value { color: #333; }
                .status-badge {
                    display: inline-block;
                    padding: 5px 12px;
                    border-radius: 20px;
                    font-size: 12px;
                    font-weight: 600;
                }
                .status-pending { background: #fff3cd; color: #856404; }
                .status-approved { background: #d4edda; color: #155724; }
            </style>
        </head>
        <body>
            <div class="header">
                <h1>🎓 SRIMCA Visitor Dashboard</h1>
                <button class="logout-btn" onclick="logout()">Logout</button>
            </div>
            
            <div class="container">
                <div class="welcome">
                    <h2>Welcome, <span id="visitorName">Visitor</span>!</h2>
                    <p>We're glad to have you at SRIMCA College. Feel free to explore our campus and chat with our AI assistant.</p>
                </div>
                
                <div class="grid">
                    <div class="card" onclick="openChat()">
                        <div class="card-icon">💬</div>
                        <h3>AI Chat Assistant</h3>
                        <p>Chat with our AI to get instant answers about courses, departments, timings, and more.</p>
                    </div>
                    
                    <div class="card">
                        <div class="card-icon">👤</div>
                        <h3>My Profile</h3>
                        <p>View your registered details, purpose of visit, and approval status.</p>
                    </div>
                    
                    <div class="card">
                        <div class="card-icon">📚</div>
                        <h3>Course Information</h3>
                        <p>Learn about our various courses and programs offered at SRIMCA College.</p>
                    </div>
                    
                    <div class="card">
                        <div class="card-icon">🏛️</div>
                        <h3>Campus Info</h3>
                        <p>Get information about our campus facilities, departments, and contact details.</p>
                    </div>
                </div>
                
                <div class="profile-card" style="margin-top: 30px;">
                    <h3>📋 My Visit Details</h3>
                    <div class="profile-item">
                        <span class="profile-label">Name:</span>
                        <span class="profile-value" id="profileName">-</span>
                    </div>
                    <div class="profile-item">
                        <span class="profile-label">Email:</span>
                        <span class="profile-value" id="profileEmail">-</span>
                    </div>
                    <div class="profile-item">
                        <span class="profile-label">Mobile:</span>
                        <span class="profile-value" id="profileMobile">-</span>
                    </div>
                    <div class="profile-item">
                        <span class="profile-label">Purpose:</span>
                        <span class="profile-value" id="profilePurpose">-</span>
                    </div>
                    <div class="profile-item">
                        <span class="profile-label">Visit Date:</span>
                        <span class="profile-value" id="profileDate">-</span>
                    </div>
                    <div class="profile-item">
                        <span class="profile-label">Status:</span>
                        <span class="profile-value"><span class="status-badge status-pending" id="profileStatus">Pending</span></span>
                    </div>
                </div>
            </div>
            
            <!-- AI Chat Widget -->
            <div class="chat-container" id="chatContainer">
                <div class="chat-header">
                    <span>🤖 AI Assistant</span>
                    <button class="chat-close" onclick="closeChat()">×</button>
                </div>
                <div class="chat-messages" id="chatMessages">
                    <div class="message bot">Hello! I'm your SRIMCA AI assistant. How can I help you today? You can ask me about courses, departments, timings, contact info, and more!</div>
                </div>
                <div class="chat-input">
                    <input type="text" id="chatInput" placeholder="Type your question..." onkeypress="handleChatKeypress(event)">
                    <button onclick="sendMessage()">Send</button>
                </div>
            </div>
            
            <script>
                // Check authentication
                const token = localStorage.getItem('token');
                const user = JSON.parse(localStorage.getItem('user') || '{}');
                
                if (!token || user.role !== 'visitor') {
                    window.location.href = '/login';
                }
                
                // Display user info
                document.getElementById('visitorName').textContent = user.name || 'Visitor';
                document.getElementById('profileName').textContent = user.name || '-';
                document.getElementById('profileEmail').textContent = user.email || '-';
                document.getElementById('profileMobile').textContent = user.mobile || '-';
                document.getElementById('profilePurpose').textContent = user.purpose || '-';
                document.getElementById('profileDate').textContent = user.visit_date ? new Date(user.visit_date).toLocaleDateString() : '-';
                document.getElementById('profileStatus').textContent = user.approval_status || 'pending';
                
                function logout() {
                    localStorage.removeItem('token');
                    localStorage.removeItem('user');
                    window.location.href = '/login';
                }
                
                function openChat() {
                    document.getElementById('chatContainer').classList.add('active');
                }
                
                function closeChat() {
                    document.getElementById('chatContainer').classList.remove('active');
                }
                
                function handleChatKeypress(event) {
                    if (event.key === 'Enter') {
                        sendMessage();
                    }
                }
                
                async function sendMessage() {
                    const input = document.getElementById('chatInput');
                    const message = input.value.trim();
                    if (!message) return;
                    
                    // Add user message
                    addMessage(message, 'user');
                    input.value = '';
                    
                    // Simulate AI response (in production, call AI API)
                    setTimeout(() => {
                        const responses = getAIResponse(message);
                        addMessage(responses, 'bot');
                    }, 500);
                }
                
                function addMessage(text, sender) {
                    const messagesDiv = document.getElementById('chatMessages');
                    const messageDiv = document.createElement('div');
                    messageDiv.className = 'message ' + sender;
                    messageDiv.textContent = text;
                    messagesDiv.appendChild(messageDiv);
                    messagesDiv.scrollTop = messagesDiv.scrollHeight;
                }
                
                function getAIResponse(query) {
                    query = query.toLowerCase();
                    
                    const responses = {
                        'admission': 'SRIMCA offers various undergraduate and postgraduate courses in Engineering, Management, and Computer Applications. For admission details, please visit our admission office or call us.',
                        'course': 'SRIMCA offers B.Tech, M.Tech, MBA, MCA, and various other courses. Our engineering programs include Computer Science, IT, Mechanical, Civil, and Electrical Engineering.',
                        'department': 'SRIMCA has several departments including Computer Science, Information Technology, Mechanical Engineering, Civil Engineering, Electrical Engineering, and Management Studies.',
                        'timing': 'College hours are from 9:00 AM to 5:00 PM Monday to Saturday. Administrative office hours are 9:30 AM to 4:30 PM.',
                        'contact': 'You can contact us at: Phone: +91-XXX-XXXXXXX, Email: info@srimca.edu.in, Address: SRIMCA College, [Location]',
                        'fee': 'Fee structure varies by course. For detailed fee information, please contact our admission department.',
                        'placement': 'SRIMCA has a dedicated placement cell that assists students with job opportunities. Many reputed companies visit our campus for recruitment.',
                        'hostel': 'Yes, we provide separate hostels for boys and girls with all necessary amenities.',
                        'library': 'Our library has a vast collection of books, journals, and digital resources. It operates from 8:00 AM to 8:00 PM.',
                        'default': 'Thank you for your question! For more detailed information, please contact our office or use the chat feature. Our team will be happy to assist you.'
                    };
                    
                    for (const [key, value] of Object.entries(responses)) {
                        if (query.includes(key)) {
                            return value;
                        }
                    }
                    return responses['default'];
                }
            </script>
        </body>
        </html>
        '''
    
    # Error handlers
    @app.errorhandler(404)
    def not_found(error):
        return jsonify({'error': 'Endpoint not found'}), 404
    
    @app.errorhandler(500)
    def internal_error(error):
        return jsonify({'error': 'Internal server error'}), 500
    
    @app.before_request
    def before_request():
        """Log requests"""
        print(f"{request.method} {request.path}")
    
    return app


# Create the app
app = create_app()

# Initialize connections on startup
def initialize_app():
    """Initialize database and Firebase connections"""
    print("Initializing SRIMCA AI Backend...")
    
    # Connect to MongoDB
    try:
        connect_to_mongodb()
        initialize_indexes()
        print("✅ MongoDB Atlas connected")
    except Exception as e:
        print(f"❌ MongoDB connection failed: {e}")
    
    # Initialize Firebase
    try:
        initialize_firebase()
        print("✅ Firebase initialized")
    except Exception as e:
        print(f"⚠️ Firebase initialization skipped: {e}")


# Run initialization
if __name__ == '__main__':
    initialize_app()
    
    config = get_config()
    print(f"\n🚀 Server running on http://0.0.0.0:{config.PORT}")
    print(f"📚 API Documentation available at http://0.0.0.0:{config.PORT}/")
    
    app.run(host='0.0.0.0', port=config.PORT, debug=config.FLASK_DEBUG)


# For gunicorn/WSGI
application = app

# Cleanup on exit
import atexit
atexit.register(close_mongodb_connection)
