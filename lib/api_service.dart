import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

// ============================================
// API Configuration
// ============================================
//
// For LOCAL DEVELOPMENT (laptop running app.py):
//   - Physical device: Use your laptop's local IP (e.g., 'http://192.168.x.x:5000')
//   - Android Emulator: Use 'http://10.0.2.2:5000'
//   - iOS Simulator: Use 'http://localhost:5000'
//
// For PRODUCTION (deployed backend):
//   - Use your Render.com URL (e.g., 'https://srimca-ai-app.onrender.com')
//
// ============================================

// Change this to your local URL when developing locally
// const String _localUrl = 'http://10.0.2.2:5000'; // Android Emulator
// const String _localUrl = 'http://localhost:5000'; // iOS Simulator
// const String _localUrl = 'http://192.168.1.x:5000'; // Physical device

const String kProductionUrl = String.fromEnvironment(
  'API_PROD_URL',
  defaultValue: 'https://srimca-ai-app.onrender.com',
);

/// API base URL - uses local URL in debug mode, production URL in release mode
String get kApiBaseUrl {
  if (kDebugMode) {
    return kProductionUrl; // Change this to your local backend URL
  }
  return kProductionUrl;
}

/// Auth Service - handles token storage and retrieval
class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  /// Save auth token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Get stored auth token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Save user data
  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
  }

  /// Get stored user data
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    if (userStr != null) {
      return jsonDecode(userStr) as Map<String, dynamic>;
    }
    return null;
  }

  /// Clear all auth data (logout)
  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;
    // Only force re-login if token is clearly expired.
    return !_isJwtExpired(token);
  }

  static bool _isJwtExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;

      final payloadJson = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final payload = jsonDecode(payloadJson);
      final exp = payload['exp'];

      if (exp is num) {
        final expMillis = exp * 1000;
        return DateTime.fromMillisecondsSinceEpoch(expMillis.toInt()).isBefore(DateTime.now());
      }
      if (exp is String) {
        final parsed = int.tryParse(exp);
        if (parsed == null) return false;
        return DateTime.fromMillisecondsSinceEpoch(parsed * 1000).isBefore(DateTime.now());
      }
      return false;
    } catch (_) {
      // If token can't be decoded, avoid forcing re-login.
      return false;
    }
  }

  /// Get user profile from backend
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$kApiBaseUrl/api/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print('Failed to get profile: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting profile: $e');
      return null;
    }
  }
}

/// API Service - handles HTTP requests with auth
class ApiService {
  static final http.Client _client = http.Client();

  /// Get headers with auth token (public)
  static Future<Map<String, String>> getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get headers with auth token (private - for internal use)
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// GET request
  static Future<http.Response> get(String endpoint, {Map<String, String>? queryParams}) async {
    final headers = await _getHeaders();
    var uri = Uri.parse('$kApiBaseUrl$endpoint');
    
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }
    
    return _client.get(uri, headers: headers).timeout(const Duration(seconds: 30));
  }

  /// POST request
  static Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$kApiBaseUrl$endpoint');
    
    return _client.post(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    ).timeout(const Duration(seconds: 30));
  }

  /// PUT request
  static Future<http.Response> put(String endpoint, {Map<String, dynamic>? body}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$kApiBaseUrl$endpoint');
    
    return _client.put(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    ).timeout(const Duration(seconds: 30));
  }

  /// DELETE request
  static Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$kApiBaseUrl$endpoint');
    
    return _client.delete(uri, headers: headers).timeout(const Duration(seconds: 30));
  }

  /// Admin Dashboard Stats - returns total counts for students, faculty, visitors, and active users
  static Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final response = await get('/api/admin/stats');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // Backend returns stats inside 'stats' key
        final stats = data['stats'] as Map<String, dynamic>? ?? data;
        // Return the data with default values for missing fields
        return {
          'total_students': stats['total_students'] ?? 0,
          'total_faculty': stats['total_faculty'] ?? 0,
          'total_visitors': stats['total_visitors'] ?? 0,
          'active_users': stats['active_users'] ?? 0,
        };
      }
      // Return default values on failure
      return {
        'total_students': 0,
        'total_faculty': 0,
        'total_visitors': 0,
        'active_users': 0,
      };
    } catch (e) {
      debugPrint('Admin Stats Error: $e');
      // Return default values on error
      return {
        'total_students': 0,
        'total_faculty': 0,
        'total_visitors': 0,
        'active_users': 0,
      };
    }
  }

  /// Get all users (admin only)
  static Future<List<Map<String, dynamic>>> getUsers({String? role, int limit = 50, int offset = 0}) async {
    try {
      final queryParams = {
        'limit': limit.toString(),
        'offset': offset.toString(),
        if (role != null) 'role': role,
      };
      
      final response = await get('/api/users/', queryParams: queryParams);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final users = data['users'] as List<dynamic>? ?? [];
        return users.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get all materials
  static Future<List<Map<String, dynamic>>> getMaterials({
    String? subject,
    String? type,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = {
        'limit': limit.toString(),
        'offset': offset.toString(),
        if (subject != null) 'subject': subject,
        if (type != null) 'type': type,
      };
      
      final response = await get('/api/materials/', queryParams: queryParams);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final materials = data['materials'] as List<dynamic>? ?? [];
        return materials.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get all notices
  static Future<List<Map<String, dynamic>>> getNotices({int limit = 50, int offset = 0}) async {
    try {
      final queryParams = {
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      
      final response = await get('/api/notices/', queryParams: queryParams);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final notices = data['notices'] as List<dynamic>? ?? [];
        return notices.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get all assignments
  static Future<List<Map<String, dynamic>>> getAssignments({int limit = 50, int offset = 0}) async {
    try {
      final queryParams = {
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      
      final response = await get('/api/assignments/', queryParams: queryParams);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final assignments = data['assignments'] as List<dynamic>? ?? [];
        return assignments.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get all FAQs
  static Future<List<Map<String, dynamic>>> getFaqs({int limit = 50, int offset = 0}) async {
    try {
      final queryParams = {
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      
      final response = await get('/api/faqs/', queryParams: queryParams);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final faqs = data['faqs'] as List<dynamic>? ?? [];
        return faqs.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Create a new notice
  static Future<Map<String, dynamic>?> createNotice({
    required String title,
    required String content,
    String priority = 'normal',
  }) async {
    try {
      final response = await post('/api/notices/', body: {
        'title': title,
        'content': content,
        'priority': priority,
      });
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['notice'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Create a new assignment
  static Future<Map<String, dynamic>?> createAssignment({
    required String title,
    required String description,
    required String dueDate,
  }) async {
    try {
      final response = await post('/api/assignments/', body: {
        'title': title,
        'description': description,
        'due_date': dueDate,
      });
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['assignment'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Create a new material
  static Future<Map<String, dynamic>?> createMaterial({
    required String title,
    required String subject,
    required String type,
    String fileUrl = '',
    String description = '',
  }) async {
    try {
      final response = await post('/api/materials/', body: {
        'title': title,
        'subject': subject,
        'type': type,
        'file_url': fileUrl,
        'description': description,
      });
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['material'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Activate user (admin only)
  static Future<bool> activateUser(String userId) async {
    try {
      final response = await post('/api/users/$userId/activate/');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Deactivate user (admin only)
  static Future<bool> deactivateUser(String userId) async {
    try {
      final response = await post('/api/users/$userId/deactivate/');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Update user (admin only) - only Faculty and Student can be edited
  static Future<bool> updateUser({
    required String userId,
    required String name,
    required String email,
    required String role,
  }) async {
    try {
      final response = await put(
        '/api/admin/users/$userId',
        body: {'name': name, 'email': email, 'role': role},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Delete material (admin only)
  static Future<bool> deleteMaterial(String materialId) async {
    try {
      final response = await delete('/api/materials/$materialId/');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Delete notice (admin only)
  static Future<bool> deleteNotice(String noticeId) async {
    try {
      final response = await delete('/api/notices/$noticeId/');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get notifications for admin dashboard
  static Future<List<Map<String, dynamic>>> getNotifications({int limit = 50}) async {
    try {
      final response = await get('/api/notifications?limit=$limit');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final notifications = data['notifications'] as List<dynamic>? ?? [];
        return notifications.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get unread notifications count
  static Future<int> getUnreadNotificationsCount() async {
    try {
      final response = await get('/api/notifications/unread-count');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['unread_count'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Mark notification as read
  static Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final response = await post('/api/notifications/$notificationId/read');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Mark all notifications as read
  static Future<bool> markAllNotificationsAsRead() async {
    try {
      final response = await post('/api/notifications/read-all');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get notifications for current user (role-based)
  static Future<List<Map<String, dynamic>>> getMyNotifications({int limit = 50}) async {
    try {
      final response = await get('/api/notifications/my?limit=$limit');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final notifications = data['notifications'] as List<dynamic>? ?? [];
        return notifications.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error getting my notifications: $e');
      return [];
    }
  }

  /// Get unread notifications count for current user
  static Future<int> getMyUnreadNotificationsCount() async {
    try {
      final response = await get('/api/notifications/unread-count/my');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['unread_count'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Create notification with specific target
  static Future<bool> createNotification({
    required String title,
    required String message,
    required String type,
    String targetRole = 'all',
    List<String> targetCourses = const [],
    List<String> targetSemesters = const [],
    String? relatedId,
    String? relatedType,
  }) async {
    try {
      final response = await post('/api/notifications', body: {
        'title': title,
        'message': message,
        'type': type,
        'target_role': targetRole,
        'target_courses': targetCourses,
        'target_semesters': targetSemesters,
        'related_id': relatedId,
        'related_type': relatedType,
      });
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Update material (admin only)
  static Future<bool> updateMaterialStatus(String materialId, String status) async {
    try {
      final response = await put('/api/materials/$materialId/', body: {'status': status});
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get chat history for a specific user
  static Future<List<Map<String, dynamic>>> getChatHistory(String userId) async {
    try {
      final response = await get('/api/chat/history/$userId');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final history = data['history'] as List<dynamic>? ?? [];
        return history.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Save chat message to history
  static Future<bool> saveChatMessage({
    required String userId,
    required String question,
    required String answer,
  }) async {
    try {
      final response = await post('/api/chat/save', body: {
        'user_id': userId,
        'question': question,
        'answer': answer,
      });
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Ask SRIMCA AI a question and get response
  static Future<String> askAI(String question) async {
    try {
      debugPrint('Sending question to AI: $question');
      final user = await AuthService.getUser();
      final response = await post('/api/ai/chat', body: {
        'question': question,
        if (user != null && (user['_id']?.toString().isNotEmpty ?? false))
          'user_id': user['_id'].toString(),
      });
      
      debugPrint('AI Response status: ${response.statusCode}');
      debugPrint('AI Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['status'] == 'success') {
          return data['answer'] as String? ?? "I apologize, but I couldn't generate a response.";
        }
      }
      
      // Return fallback message on error
      return "I apologize, but I'm having trouble processing your request right now. Please try again later.";
    } catch (e) {
      debugPrint('Ask AI Error: $e');
      return "I apologize, but I'm having trouble connecting to the AI service. Please check your internet connection and try again.";
    }
  }

  /// Get AI monitoring queries and stats
  static Future<Map<String, dynamic>> getAiMonitoringData({String period = 'all', int limit = 100}) async {
    try {
      final response = await get(
        '/api/ai/queries',
        queryParams: {
          'period': period,
          'limit': limit.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final queries = (data['queries'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        final stats = (data['stats'] as Map<String, dynamic>? ?? {});
        return {
          'queries': queries,
          'stats': {
            'total_queries': stats['total_queries'] ?? queries.length,
            'today_queries': stats['today_queries'] ?? 0,
            'avg_response': stats['avg_response'] ?? '<2s',
          },
        };
      }

      return {
        'queries': <Map<String, dynamic>>[],
        'stats': {
          'total_queries': 0,
          'today_queries': 0,
          'avg_response': '<2s',
        },
      };
    } catch (e) {
      debugPrint('AI Monitoring Data Error: $e');
      return {
        'queries': <Map<String, dynamic>>[],
        'stats': {
          'total_queries': 0,
          'today_queries': 0,
          'avg_response': '<2s',
        },
      };
    }
  }

  /// Get reports & analytics data for admin dashboard
  static Future<Map<String, dynamic>> getReportsAnalytics() async {
    try {
      final response = await get('/api/admin/reports/analytics');
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {
        'overview': {
          'total_users': 0,
          'active_today': 0,
          'total_queries': 0,
          'avg_response': '<2s',
          'today_queries': 0,
        },
        'distribution': {
          'students': 0,
          'faculty': 0,
          'visitors': 0,
          'admins': 0,
        },
        'monthly_activity': <Map<String, dynamic>>[],
      };
    } catch (e) {
      debugPrint('Reports Analytics Error: $e');
      return {
        'overview': {
          'total_users': 0,
          'active_today': 0,
          'total_queries': 0,
          'avg_response': '<2s',
          'today_queries': 0,
        },
        'distribution': {
          'students': 0,
          'faculty': 0,
          'visitors': 0,
          'admins': 0,
        },
        'monthly_activity': <Map<String, dynamic>>[],
      };
    }
  }

  /// Get database management overview data
  static Future<Map<String, dynamic>> getDatabaseOverview() async {
    try {
      final response = await get('/api/admin/database/overview');
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {
        'stats': {
          'users': 0,
          'notices': 0,
          'materials': 0,
          'queries': 0,
          'notifications': 0,
        },
        'info': {
          'database_name': 'srimca_ai',
          'version': '1.0.0',
          'size_mb': 0,
          'last_updated': '',
          'last_backup': null,
        },
      };
    } catch (e) {
      debugPrint('Database Overview Error: $e');
      return {
        'stats': {
          'users': 0,
          'notices': 0,
          'materials': 0,
          'queries': 0,
          'notifications': 0,
        },
        'info': {
          'database_name': 'srimca_ai',
          'version': '1.0.0',
          'size_mb': 0,
          'last_updated': '',
          'last_backup': null,
        },
      };
    }
  }

  /// Run database backup action
  static Future<Map<String, dynamic>> backupDatabase() async {
    try {
      final response = await post('/api/admin/database/backup');
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'error': 'Backup failed'};
    } catch (e) {
      return {'error': 'Backup failed: $e'};
    }
  }

  /// Run database restore action
  static Future<Map<String, dynamic>> restoreDatabase() async {
    try {
      final response = await post('/api/admin/database/restore');
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'error': 'Restore failed'};
    } catch (e) {
      return {'error': 'Restore failed: $e'};
    }
  }

  /// Run database optimization action
  static Future<bool> optimizeDatabase() async {
    try {
      final response = await post('/api/admin/database/optimize');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Run database clear-cache action
  static Future<bool> clearDatabaseCache() async {
    try {
      final response = await post('/api/admin/database/clear-cache');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get visitor inquiries for faculty page
  static Future<List<Map<String, dynamic>>> getFacultyVisitorInquiries({int limit = 100}) async {
    try {
      final response = await get(
        '/api/users/faculty/visitor-inquiries',
        queryParams: {'limit': limit.toString()},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final inquiries = data['inquiries'] as List<dynamic>? ?? [];
        return inquiries.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Faculty Visitor Inquiries Error: $e');
      return [];
    }
  }

  /// Respond to visitor inquiry as faculty
  static Future<bool> respondFacultyVisitorInquiry({
    required String visitorId,
    required String status,
    String facultyReply = '',
  }) async {
    try {
      final response = await put(
        '/api/users/faculty/visitor-inquiries/$visitorId/respond',
        body: {
          'status': status,
          'faculty_reply': facultyReply,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Respond Faculty Visitor Inquiry Error: $e');
      return false;
    }
  }

  /// Get notifications for a specific user
  static Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    try {
      final response = await get('/api/notifications/user/$userId');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final notifications = data['notifications'] as List<dynamic>? ?? [];
        return notifications.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get all visitors (admin only)
  static Future<List<Map<String, dynamic>>> getVisitors() async {
    try {
      final response = await get('/api/admin/visitors');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final visitors = data['visitors'] as List<dynamic>? ?? [];
        return visitors.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Get Visitors Error: $e');
      return [];
    }
  }

  /// Update visitor status (admin only)
  static Future<bool> updateVisitorStatus(String visitorId, String status) async {
    try {
      final response = await put('/api/admin/visitors/$visitorId', body: {'status': status});
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Update Visitor Status Error: $e');
      return false;
    }
  }

  /// Forgot Password - Student submits email request
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await post('/api/users/forgot-password', body: {'email': email});
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message'] ?? 'Request sent successfully'};
      }
      final data = jsonDecode(response.body);
      return {'success': false, 'error': data['error'] ?? 'Failed to send request'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  /// Get Password Reset Requests (admin only)
  static Future<List<Map<String, dynamic>>> getPasswordRequests({int limit = 100}) async {
    try {
      final response = await get('/api/users/admin/password-requests', queryParams: {'limit': limit.toString()});
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final requests = data['requests'] as List<dynamic>? ?? [];
        return requests.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Get password requests error: $e');
      return [];
    }
  }

  /// Admin Reset Password for request
  static Future<Map<String, dynamic>?> adminResetPassword(String requestId) async {
    try {
      final response = await post('/api/users/admin/reset-password/$requestId');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      }
      final data = jsonDecode(response.body);
      return {'success': false, 'error': data['error'] ?? 'Reset failed'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
}

