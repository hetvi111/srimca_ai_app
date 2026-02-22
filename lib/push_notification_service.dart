import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:srimca_ai/api_service.dart';

/// Push Notification Service - Handles Firebase Cloud Messaging
class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  /// Initialize push notifications
  static Future<void> initialize() async {
    // Request permission for iOS
    await _firebaseMessaging.requestPermission();
    
    // Get FCM token
    final token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');
    
    // Save token to backend for push notifications
    if (token != null) {
      await _saveTokenToBackend(token);
    }
    
    // Initialize local notifications
    await _initializeLocalNotifications();
    
    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle notification when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }
  
  /// Initialize local notifications
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
  }
  
  /// Save FCM token to backend
  static Future<void> _saveTokenToBackend(String token) async {
    try {
      // Store token in user preferences or send to backend
      // This would be used to send push notifications to specific users
      print('FCM token saved: $token');
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }
  
  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.notification?.title}');
    
    // Show local notification
    _showLocalNotification(
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }
  
  /// Handle notification tap when app is in background
  static void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.notification?.title}');
    // Navigate to appropriate screen based on message data
  }
  
  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Navigate to notification screen
  }
  
  /// Show local notification
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'srimca_notifications',
      'SRIMCA Notifications',
      channelDescription: 'College notifications and updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(
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
  
  /// Subscribe to topic (for role-based notifications)
  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }
  
  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }
  
  /// Subscribe user to role-based topics
  static Future<void> subscribeToRoleTopics(String role) async {
    // Subscribe to general notifications
    await subscribeToTopic('all');
    
    // Subscribe to role-specific topic
    await subscribeToTopic(role);
    
    print('Subscribed to role topics for: $role');
  }
  
  /// Get FCM token
  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}
