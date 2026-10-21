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
//   - Use your Firebase-hosted backend URL (Cloud Run/Functions)
//   - Example: https://<region>-<project-id>.cloudfunctions.net/api
//
// ============================================

// Change this to your local URL when developing locally
// const String _localUrl = 'http://10.0.2.2:5000'; // Android Emulator
// const String _localUrl = 'http://localhost:5000'; // iOS Simulator
// const String _localUrl = 'http://192.168.1.x:5000'; // Physical device

const String kProductionUrl = String.fromEnvironment(
  'API_PROD_URL',
  defaultValue: 'https://srimca.vercel.app',
);

String get kApiBaseUrl {
  const definedUrl = String.fromEnvironment('API_PROD_URL', defaultValue: '');
  if (definedUrl.isNotEmpty) {
    return definedUrl;
  }
  if (kDebugMode) {
    return 'http://127.0.0.1:5000';
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
        return DateTime.fromMillisecondsSinceEpoch(
          expMillis.toInt(),
        ).isBefore(DateTime.now());
      }
      if (exp is String) {
        final parsed = int.tryParse(exp);
        if (parsed == null) return false;
        return DateTime.fromMillisecondsSinceEpoch(
          parsed * 1000,
        ).isBefore(DateTime.now());
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
      final response = await http
          .get(
            Uri.parse('$kApiBaseUrl/api/users/profile'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 60));

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
  static Future<http.Response> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    final headers = await _getHeaders();
    var uri = Uri.parse('$kApiBaseUrl$endpoint');

    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    return _client
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 60));
  }

  /// POST request
  static Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$kApiBaseUrl$endpoint');

    return _client
        .post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(const Duration(seconds: 60));
  }

  /// PUT request
  static Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$kApiBaseUrl$endpoint');

    return _client
        .put(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(const Duration(seconds: 60));
  }

  /// PATCH request
  static Future<http.Response> patch(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$kApiBaseUrl$endpoint');

    return _client
        .patch(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(const Duration(seconds: 60));
  }

  /// DELETE request
  static Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$kApiBaseUrl$endpoint');

    return _client
        .delete(uri, headers: headers)
        .timeout(const Duration(seconds: 30));
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
  static Future<List<Map<String, dynamic>>> getUsers({
    String? role,
    int limit = 50,
    int offset = 0,
  }) async {
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
  static Future<List<Map<String, dynamic>>> getNotices({
    int limit = 50,
    int offset = 0,
  }) async {
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
  static Future<List<Map<String, dynamic>>> getAssignments({
    int limit = 50,
    int offset = 0,
  }) async {
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
  static Future<List<Map<String, dynamic>>> getFaqs({
    int limit = 50,
    int offset = 0,
  }) async {
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
    String category = 'notice',
    String targetRole = 'student',
  }) async {
    try {
      final response = await post(
        '/api/notices/',
        body: {
          'title': title,
          'content': content,
          'priority': priority,
          'category': category,
          'target_role': targetRole,
        },
      );

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
    String subject = 'General',
  }) async {
    try {
      final response = await post(
        '/api/assignments/',
        body: {
          'title': title,
          'description': description,
          'due_date': dueDate,
          'subject': subject,
        },
      );

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
      final response = await post(
        '/api/materials/',
        body: {
          'title': title,
          'subject': subject,
          'type': type,
          'file_url': fileUrl,
          'description': description,
        },
      );

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
  static Future<List<Map<String, dynamic>>> getNotifications({
    int limit = 50,
  }) async {
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
  static Future<List<Map<String, dynamic>>> getMyNotifications({
    int limit = 50,
    String? type,
  }) async {
    try {
      String url = '/api/notifications/my?limit=$limit';
      if (type != null && type.isNotEmpty) {
        url += '&type=$type';
      }
      final response = await get(url);

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

  /// Save user's FCM device token to backend
  static Future<bool> saveFcmToken(String token) async {
    try {
      final response = await post(
        '/api/notifications/save-fcm-token',
        body: {'fcm_token': token},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error saving FCM token: $e');
      return false;
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
      final response = await post(
        '/api/notifications',
        body: {
          'title': title,
          'message': message,
          'type': type,
          'target_role': targetRole,
          'target_courses': targetCourses,
          'target_semesters': targetSemesters,
          'related_id': relatedId,
          'related_type': relatedType,
        },
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Update material (admin only)
  static Future<bool> updateMaterialStatus(
    String materialId,
    String status,
  ) async {
    try {
      final response = await put(
        '/api/materials/$materialId/',
        body: {'status': status},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get chat history for a specific user
  static Future<List<Map<String, dynamic>>> getChatHistory(
    String userId,
  ) async {
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
      final response = await post(
        '/api/chat/save',
        body: {'user_id': userId, 'question': question, 'answer': answer},
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Ask SRIMCA AI a question and get response
  static Future<String> askAI(String question) async {
    final result = await askAIDetailed(question);
    return result['answer'] as String;
  }

  /// Ask SRIMCA AI a question and get full response including suggestions and guidance
  static Future<Map<String, dynamic>> askAIDetailed(String question) async {
    try {
      debugPrint('Sending question to AI: $question');
      final user = await AuthService.getUser();
      final response = await post(
        '/api/ai/chat',
        body: {
          'question': question,
          if (user != null) ...{
            if (user['_id']?.toString().isNotEmpty ?? false)
              'user_id': user['_id'].toString(),
            if (user['role'] != null) 'role': user['role'].toString(),
            if (user['course'] != null) 'course': user['course'].toString(),
            if (user['semester'] != null) 'semester': user['semester'].toString(),
          }
        },
      );

      debugPrint('AI Response status: ${response.statusCode}');
      debugPrint('AI Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['status'] == 'success' || data['success'] == true) {
          final followUps = (data['follow_up_questions'] as List? ?? data['suggestions'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              <String>[];
          
          Map<String, dynamic>? locationMap;
          if (data['location'] != null && data['location'] is Map) {
            locationMap = Map<String, dynamic>.from(data['location'] as Map);
          }

          return {
            'answer': data['answer'] as String? ??
                data['reply'] as String? ??
                "I apologize, but I couldn't generate a response.",
            'type': data['type'] as String? ?? 'text',
            'location': locationMap,
            'follow_up_questions': followUps,
            'suggestions': followUps,
            'personalized_guidance':
                data['personalized_guidance'] as String? ?? "",
          };
        }
      }

      // Return fallback message on error
      return {
        'answer':
            "I apologize, but I'm having trouble processing your request right now. Please try again later.",
        'type': 'text',
        'location': null,
        'follow_up_questions': <String>[],
        'suggestions': <String>[],
        'personalized_guidance': "",
      };
    } catch (e) {
      debugPrint('Ask AI Error: $e');
      return {
        'answer':
            "I apologize, but I'm having trouble connecting to the AI service. Please check your internet connection and try again.",
        'type': 'text',
        'location': null,
        'follow_up_questions': <String>[],
        'suggestions': <String>[],
        'personalized_guidance': "",
      };
    }
  }

  /// Ask SRIMCA AI and get structured response with campus location details if available
  static Future<Map<String, dynamic>> askAIChat(String question) async {
    return await askAIDetailed(question);
  }

  /// Get AI monitoring queries and stats
  static Future<Map<String, dynamic>> getAiMonitoringData({
    String period = 'all',
    int limit = 100,
  }) async {
    try {
      final response = await get(
        '/api/ai/queries',
        queryParams: {'period': period, 'limit': limit.toString()},
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
  static Future<List<Map<String, dynamic>>> getFacultyVisitorInquiries({
    int limit = 100,
  }) async {
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
        body: {'status': status, 'faculty_reply': facultyReply},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Respond Faculty Visitor Inquiry Error: $e');
      return false;
    }
  }

  /// Get notifications for a specific user
  static Future<List<Map<String, dynamic>>> getUserNotifications(
    String userId,
  ) async {
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
  static Future<bool> updateVisitorStatus(
    String visitorId,
    String status,
  ) async {
    try {
      final response = await put(
        '/api/admin/visitors/$visitorId',
        body: {'status': status},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Update Visitor Status Error: $e');
      return false;
    }
  }

  /// Forgot Password - Student submits email request
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await post(
        '/api/users/forgot-password',
        body: {'email': email},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Request sent successfully',
        };
      }
      final data = jsonDecode(response.body);
      return {
        'success': false,
        'error': data['error'] ?? 'Failed to send request',
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  /// Get Password Reset Requests (admin only)
  static Future<List<Map<String, dynamic>>> getPasswordRequests({
    int limit = 100,
  }) async {
    try {
      final response = await get(
        '/api/users/admin/password-requests',
        queryParams: {'limit': limit.toString()},
      );

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

  /// Admin Reset Password for request.
  /// Students: pass [studentEnrollment] matching DB. Faculty: pass [facultyEmail] matching request.
  /// Other roles: pass [confirmEmail] matching the account email.
  static Future<Map<String, dynamic>?> adminResetPassword(
    String requestId, {
    String? studentEnrollment,
    String? facultyEmail,
    String? confirmEmail,
    String? newPassword,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (newPassword != null && newPassword.isNotEmpty) {
        body['new_password'] = newPassword;
      }
      if (studentEnrollment != null && studentEnrollment.isNotEmpty) {
        body['student_enrollment'] = studentEnrollment;
      }
      if (facultyEmail != null && facultyEmail.isNotEmpty) {
        body['faculty_email'] = facultyEmail;
      }
      if (confirmEmail != null && confirmEmail.isNotEmpty) {
        body['confirm_email'] = confirmEmail;
      }
      final response = await post(
        '/api/users/admin/reset-password/$requestId',
        body: body.isEmpty ? null : body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {'success': false, 'error': data['error'] ?? 'Reset failed'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  /// Admin: Get single user by ID
  static Future<Map<String, dynamic>?> getAdminUserById(String userId) async {
    try {
      final response = await get('/api/admin/users/$userId');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['user'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('Get admin user by id error: $e');
      return null;
    }
  }

  /// Admin: Update user with full fields
  static Future<Map<String, dynamic>> adminUpdateUser({
    required String userId,
    required String name,
    required String email,
    required String role,
    required String phone,
    required String gender,
    required bool isActive,
  }) async {
    try {
      final response = await put(
        '/api/admin/users/$userId',
        body: {
          'name': name,
          'email': email,
          'role': role,
          'mobile': phone,
          'gender': gender,
          'is_active': isActive,
          // Keep profile fields too for UI consistency
          'profile_phone': phone,
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {'success': true, 'data': data};
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {'success': false, 'error': data['error'] ?? 'Update failed'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // REMOVED: OTP methods - direct registration now used

  /// Register a new visitor
  static Future<Map<String, dynamic>> registerVisitor({
    required String name,
    required String email,
    required String phone,
    required String purpose,
  }) async {
    return registerUser(
      body: {
        'name': name,
        'email': email,
        'phone': phone,
        'purpose': purpose,
        'role': 'visitor',
      },
    );
  }

  /// Complete user registration after OTP verification
  static Future<Map<String, dynamic>> registerUser({
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await post('/api/register', body: body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'message': data['message'] ?? 'Registration successful',
          'data': data,
        };
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'success': false,
        'error': data['error'] ?? data['message'] ?? 'Registration failed',
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  /// Get visitor profile (static wrapper)
  static Future<Map<String, dynamic>?> getProfile(
    String token,
    String visitorId,
  ) async {
    try {
      final response = await get('/api/visitor/profile/$visitorId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['profile'] as Map<String, dynamic>? ?? data;
      }
      return null;
    } catch (e) {
      debugPrint('Get visitor profile error: $e');
      return null;
    }
  }

  /// Get visitor visit history
  static Future<List> getHistory(String token, String visitorId) async {
    try {
      final response = await get('/api/visitor/history/$visitorId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['history'] as List? ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('Get visitor history error: $e');
      return [];
    }
  }

  /// Get visitor profile
  Future<Map<String, dynamic>?> getVisitorProfile(String visitorId) async {
    try {
      final response = await get('/api/visitor/profile/$visitorId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['profile'] as Map<String, dynamic>? ?? data;
      }
      return null;
    } catch (e) {
      debugPrint('Get visitor profile error: $e');
      return null;
    }
  }

  /// Update visitor profile
  static Future<Map<String, dynamic>> updateVisitorProfile({
    required String visitorId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await patch(
        '/api/visitor/profile/$visitorId',
        body: data,
      );

      if (response.statusCode == 200) {
        final dataResponse = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'message': dataResponse['message'] ?? 'Profile updated',
          'data': dataResponse,
        };
      }
      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'success': false,
        'error':
            errorData['error'] ??
            errorData['message'] ??
            'Profile update failed',
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  /// Get visitor history/logs
  static Future<Map<String, dynamic>> getVisitorHistory(
    String visitorId,
  ) async {
    try {
      final response = await get('/api/visitor/history/$visitorId');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'success': false, 'history': [], 'total': 0};
    } catch (e) {
      debugPrint('Get visitor history error: $e');
      return {'success': false, 'history': [], 'total': 0};
    }
  }

  /// Generate visitor QR pass
  static Future<Map<String, dynamic>?> generateVisitorQR(
    String visitorId,
  ) async {
    try {
      final response = await get('/api/visitor/qr/$visitorId');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Generate visitor QR error: $e');
      return null;
    }
  }

  /// Check-in from QR scan - accepts raw QR code string
  static Future<Map<String, dynamic>?> checkInFromQR(String qrCode) async {
    try {
      final response = await post(
        '/api/visitor/qr/checkin',
        body: {'qr_code': qrCode},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('QR check-in error: $e');
      return null;
    }
  }

  /// Visitor check-in with explicit visitor ID and token
  static Future<Map<String, dynamic>> visitorCheckin({
    required String visitorId,
    required String token,
  }) async {
    try {
      final response = await post(
        '/api/visitor/checkin',
        body: {'vid': visitorId, 'token': token},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {'success': false, 'error': data['error'] ?? 'Check-in failed'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // =========================================================================
  // SEVEN ADMIN DASHBOARD MODULES API METHODS
  // =========================================================================

  // --- Module 1: Dashboard Overview ---
  static Future<Map<String, dynamic>?> getDashboardLiveStats() async {
    try {
      final response = await get('/api/admin/dashboard/stats');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['stats'] as Map<String, dynamic>? ?? data;
      }
      return null;
    } catch (e) {
      debugPrint('Error getDashboardLiveStats: $e');
      return null;
    }
  }

  // --- Module 2: Campus Navigation Management ---
  static Future<List<Map<String, dynamic>>> getCampusLocations({
    String? search,
    String? category,
    String? verified,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (category != null && category != 'all') queryParams['category'] = category;
      if (verified != null && verified != 'all') queryParams['verified'] = verified;

      final response = await get('/api/admin/campus-locations', queryParams: queryParams);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['locations'] as List<dynamic>? ?? [];
        return list.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Error getCampusLocations: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> createCampusLocation(Map<String, dynamic> locationData) async {
    try {
      final response = await post('/api/admin/campus-locations', body: locationData);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'success': response.statusCode == 201,
        'message': data['message'] ?? data['error'] ?? '',
        'location': data['location'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateCampusLocation(String id, Map<String, dynamic> locationData) async {
    try {
      final response = await put('/api/admin/campus-locations/$id', body: locationData);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? data['error'] ?? '',
        'location': data['location'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<bool> deleteCampusLocation(String id) async {
    try {
      final response = await delete('/api/admin/campus-locations/$id');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleteCampusLocation: $e');
      return false;
    }
  }

  // --- Module 3: AI Knowledge Base ---
  static Future<List<Map<String, dynamic>>> getKnowledgeEntries({
    String? search,
    String? category,
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (category != null && category != 'all') queryParams['category'] = category;
      if (status != null && status != 'all') queryParams['status'] = status;

      final response = await get('/api/admin/knowledge', queryParams: queryParams);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['entries'] as List<dynamic>? ?? [];
        return list.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Error getKnowledgeEntries: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> createKnowledgeEntry(Map<String, dynamic> entryData) async {
    try {
      final response = await post('/api/admin/knowledge', body: entryData);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'success': response.statusCode == 201,
        'message': data['message'] ?? data['error'] ?? '',
        'entry': data['entry'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateKnowledgeEntry(String id, Map<String, dynamic> entryData) async {
    try {
      final response = await put('/api/admin/knowledge/$id', body: entryData);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? data['error'] ?? '',
        'entry': data['entry'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<bool> deleteKnowledgeEntry(String id) async {
    try {
      final response = await delete('/api/admin/knowledge/$id');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleteKnowledgeEntry: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getUnresolvedQueries({String? status}) async {
    try {
      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty) queryParams['status'] = status;

      final response = await get('/api/admin/knowledge/unresolved', queryParams: queryParams);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['queries'] as List<dynamic>? ?? [];
        return list.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Error getUnresolvedQueries: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> resolveUnresolvedQuery({
    required String queryId,
    required String approvedAnswer,
    required String category,
    String? title,
  }) async {
    try {
      final response = await post(
        '/api/admin/knowledge/resolve-query',
        body: {
          'query_id': queryId,
          'approved_answer': approvedAnswer,
          'category': category,
          if (title != null && title.isNotEmpty) 'title': title,
        },
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? data['error'] ?? '',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // --- Module 4: Notices & Notifications ---
  static Future<List<Map<String, dynamic>>> getAdminNoticesList({
    String? search,
    String? category,
    String? status,
    String? targetRole,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (category != null && category != 'all') queryParams['category'] = category;
      if (status != null && status != 'all') queryParams['status'] = status;
      if (targetRole != null && targetRole != 'all') queryParams['target_role'] = targetRole;

      final response = await get('/api/admin/notices', queryParams: queryParams);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['notices'] as List<dynamic>? ?? [];
        return list.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Error getAdminNoticesList: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> createAdminNoticeItem(Map<String, dynamic> noticeData) async {
    try {
      final response = await post('/api/admin/notices', body: noticeData);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'success': response.statusCode == 201,
        'message': data['message'] ?? data['error'] ?? '',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateAdminNoticeItem(String id, Map<String, dynamic> noticeData) async {
    try {
      final response = await put('/api/admin/notices/$id', body: noticeData);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? data['error'] ?? '',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<bool> deleteAdminNoticeItem(String id) async {
    try {
      final response = await delete('/api/admin/notices/$id');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleteAdminNoticeItem: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getAdminNotificationStats() async {
    try {
      final response = await get('/api/admin/notifications/stats');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['stats'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getAdminNotificationStats: $e');
      return null;
    }
  }

  // --- Module 5: User Management ---
  static Future<List<Map<String, dynamic>>> getAdminUsersList({
    String? search,
    String? role,
    String? status,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (role != null && role != 'all') queryParams['role'] = role;
      if (status != null && status != 'all') queryParams['status'] = status;

      final response = await get('/api/admin/users', queryParams: queryParams);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['users'] as List<dynamic>? ?? [];
        return list.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Error getAdminUsersList: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> createAdminUserAccount(Map<String, dynamic> userData) async {
    try {
      final response = await post('/api/admin/users', body: userData);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'success': response.statusCode == 201,
        'message': data['message'] ?? data['error'] ?? '',
        'user': data['user'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateAdminUserAccount(String id, Map<String, dynamic> userData) async {
    try {
      final response = await put('/api/admin/users/$id', body: userData);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? data['error'] ?? '',
        'user': data['user'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<bool> toggleAdminUserStatus(String id) async {
    try {
      final response = await post('/api/admin/users/$id/toggle-status');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error toggleAdminUserStatus: $e');
      return false;
    }
  }

  static Future<bool> deleteAdminUserAccount(String id) async {
    try {
      final response = await delete('/api/admin/users/$id');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleteAdminUserAccount: $e');
      return false;
    }
  }

  // --- Module 6: Visitor Pass Approval ---
  static Future<List<Map<String, dynamic>>> getVisitorPasses({
    String? status,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null && status != 'all') queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await get('/api/admin/visitor-passes', queryParams: queryParams);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['passes'] as List<dynamic>? ?? [];
        return list.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Error getVisitorPasses: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> approveVisitorPass(String id, {String? remarks, String? validUntil}) async {
    try {
      final response = await post(
        '/api/admin/visitor-passes/$id/approve',
        body: {
          if (remarks != null) 'remarks': remarks,
          if (validUntil != null) 'valid_until': validUntil,
        },
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? data['error'] ?? '',
        'pass_token': data['pass_token'],
        'verification_url': data['verification_url'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> rejectVisitorPass(String id, {String? reason}) async {
    try {
      final response = await post(
        '/api/admin/visitor-passes/$id/reject',
        body: {
          if (reason != null) 'reason': reason,
        },
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? data['error'] ?? '',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // --- Module 7: Reports & Activity Logs ---
  static Future<Map<String, dynamic>?> getAdminReportsSummary({String timeframe = '30days'}) async {
    try {
      final response = await get('/api/admin/reports/summary', queryParams: {'timeframe': timeframe});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['reports'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getAdminReportsSummary: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getAdminActivityLogs({
    String? search,
    String? module,
    String? action,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (module != null && module != 'all') queryParams['module'] = module;
      if (action != null && action != 'all') queryParams['action'] = action;

      final response = await get('/api/admin/activity-logs', queryParams: queryParams);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['logs'] as List<dynamic>? ?? [];
        return list.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Error getAdminActivityLogs: $e');
      return [];
    }
  }

  static Future<String?> exportReportCsv(String reportType) async {
    try {
      final response = await get('/api/admin/reports/export/$reportType');
      if (response.statusCode == 200) {
        return response.body;
      }
      return null;
    } catch (e) {
      debugPrint('Error exportReportCsv: $e');
      return null;
    }
  }
}

