import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

const String kProductionUrl = String.fromEnvironment(
  'API_PROD_URL',
  defaultValue: 'https://srimca-ai-app.onrender.com',
);

/// API base URL that returns production URL in release mode and local URL in debug mode
String get kApiBaseUrl => kReleaseMode ? kProductionUrl : 'http://172.31.229.182:5000';

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
    return token != null && token.isNotEmpty;
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
        // Backend returns stats directly from the API
        // Return the data with default values for missing fields
        return {
          'total_students': data['total_students'] ?? 0,
          'total_faculty': data['total_faculty'] ?? 0,
          'total_visitors': data['total_visitors'] ?? 0,
          'active_users': data['active_users'] ?? 0,
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
}
