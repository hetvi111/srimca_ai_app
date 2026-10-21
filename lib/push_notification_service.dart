import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:srimca_ai/api_service.dart';
import 'package:srimca_ai/local_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Global navigator key for notification click navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Top-level FCM Background Message Handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling background FCM message: ${message.messageId}");
}

/// Push Notification Service - Handles Firebase Cloud Messaging
class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Android Notification Channels
  static const AndroidNotificationChannel highChannel = AndroidNotificationChannel(
    'srimca_high_priority',
    'High Priority Notifications',
    description: 'Emergency alerts and important exam schedules',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
    'srimca_default',
    'Default Notifications',
    description: 'General notices, assignments, and campus events',
    importance: Importance.defaultImportance,
  );

  static const AndroidNotificationChannel lowChannel = AndroidNotificationChannel(
    'srimca_low',
    'Low Priority Notifications',
    description: 'General informational updates and circulars',
    importance: Importance.low,
  );

  /// Initialize push notifications
  static Future<void> initialize() async {
    try {
      // Request permission for iOS/mobile
      if (!kIsWeb) {
        await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }
      
      // Get FCM token (works on web too)
      final token = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $token');
      
      // Save token to backend for push notifications
      if (token != null) {
        await _saveTokenToBackend(token);
      }

      // Auto-sync token when Firebase refreshes it
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        debugPrint('FCM Token refreshed: $newToken');
        await _saveTokenToBackend(newToken);
      });
      
      // Initialize local notifications - mobile only
      if (!kIsWeb) {
        await _initializeLocalNotifications();
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
        
        // Handle notification launch from terminated state
        final initialMessage = await _firebaseMessaging.getInitialMessage();
        if (initialMessage != null) {
          _handleNotificationTap(initialMessage);
        }
      }
    } catch (e) {
      debugPrint('PushNotificationService init error: $e');
    }
  }
  
  /// Initialize local notifications & register Android Channels
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android Notification Channels
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(highChannel);
      await androidPlugin.createNotificationChannel(defaultChannel);
      await androidPlugin.createNotificationChannel(lowChannel);
      debugPrint('Registered Android Notification Channels (High, Default, Low)');
    }
  }
  
  /// Save FCM token to backend
  static Future<void> _saveTokenToBackend(String token) async {
    try {
      final success = await ApiService.saveFcmToken(token);
      if (success) {
        debugPrint('FCM token registered on backend');
      } else {
        debugPrint('FCM token acquired: $token');
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.notification?.title}');
    
    final priority = message.data['priority'] ?? 'medium';
    
    _showLocalNotification(
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
      priorityTag: priority,
    );
  }
  
  /// Handle notification tap when app is opened via push notification
  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.notification?.title}');
    navigateFromData(message.data);
  }
  
  /// Handle local notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped payload: ${response.payload}');
    navigatorKey.currentState?.pushNamed('/student-notifications');
  }

  /// Perform navigation based on notification data payload
  static void navigateFromData(Map<String, dynamic> data) {
    final route = data['route'] ?? data['related_type'];
    debugPrint('Navigating from notification route: $route');

    if (route == 'notice' || route == 'exam' || route == 'notifications' || route == 'assignment') {
      navigatorKey.currentState?.pushNamed('/student-notifications');
    }
  }
  
  /// Show local notification with appropriate channel priority
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String priorityTag = 'medium',
  }) async {
    AndroidNotificationDetails androidDetails;

    if (priorityTag == 'high' || priorityTag == 'emergency') {
      androidDetails = AndroidNotificationDetails(
        highChannel.id,
        highChannel.name,
        channelDescription: highChannel.description,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );
    } else if (priorityTag == 'low') {
      androidDetails = AndroidNotificationDetails(
        lowChannel.id,
        lowChannel.name,
        channelDescription: lowChannel.description,
        importance: Importance.low,
        priority: Priority.low,
      );
    } else {
      androidDetails = AndroidNotificationDetails(
        defaultChannel.id,
        defaultChannel.name,
        channelDescription: defaultChannel.description,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );
    }
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }
  
  /// Subscribe to topic (for role/course/sem notifications)
  static Future<void> subscribeToTopic(String topic) async {
    final cleanTopic = topic.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '_');
    if (cleanTopic.isNotEmpty) {
      await _firebaseMessaging.subscribeToTopic(cleanTopic);
      debugPrint('Subscribed to FCM topic: $cleanTopic');
    }
  }
  
  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    final cleanTopic = topic.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '_');
    if (cleanTopic.isNotEmpty) {
      await _firebaseMessaging.unsubscribeFromTopic(cleanTopic);
      debugPrint('Unsubscribed from FCM topic: $cleanTopic');
    }
  }
  
  /// Subscribe user to role-based and course/semester topics
  /// Example: subscribeToRoleAndCourseTopics(role: 'student', course: 'mca', semester: 'sem3')
  /// Subscribes to: 'all', 'student', 'mca', 'mca_sem3', 'exam', 'notice', 'event'
  static Future<void> subscribeToRoleAndCourseTopics({
    required String role,
    String? course,
    String? semester,
  }) async {
    try {
      await subscribeToTopic('all');
      await subscribeToTopic(role);
      
      if (course != null && course.isNotEmpty) {
        final courseClean = course.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        await subscribeToTopic(courseClean);
        
        if (semester != null && semester.isNotEmpty) {
          final semClean = semester.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
          await subscribeToTopic('${courseClean}_$semClean');
        }
      }
      
      await subscribeToTopic('exam');
      await subscribeToTopic('notice');
      await subscribeToTopic('event');
    } catch (e) {
      debugPrint('Error subscribing to topics: $e');
    }
  }
  
  /// Legacy wrapper for backwards compatibility
  static Future<void> subscribeToRoleTopics(String role) async {
    await subscribeToRoleAndCourseTopics(role: role);
  }

  /// Send an instant local test notification on device
  static Future<void> showTestNotification() async {
    await LocalNotificationService.showNotification(
      id: 99999,
      title: '🔔 SRIMCA AI Test Notification',
      body: 'Notifications are active and working on your Android device!',
      priorityTag: 'high',
    );
  }

  /// Get FCM token
  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}

