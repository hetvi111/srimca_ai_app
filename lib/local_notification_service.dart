import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:srimca_ai/api_service.dart';
import 'package:srimca_ai/push_notification_service.dart' show navigatorKey;

/// Local Notification Service - Pure Local Notifications & Foreground Polling
class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  static Timer? _pollingTimer;
  static const String _notifiedIdsKey = 'notified_notice_ids';
  static bool _isChecking = false;

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

  /// Initialize local notifications plugin & channels
  static Future<void> initialize() async {
    try {
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

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (!kIsWeb) {
        final androidPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          await androidPlugin.createNotificationChannel(highChannel);
          await androidPlugin.createNotificationChannel(defaultChannel);
          await androidPlugin.createNotificationChannel(lowChannel);
          await androidPlugin.requestNotificationsPermission();
          debugPrint('LocalNotificationService: Notification channels & permissions setup completed.');
        }
      }
    } catch (e) {
      debugPrint('LocalNotificationService initialize error: $e');
    }
  }

  /// Handle notification tap action
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped with payload: ${response.payload}');
    try {
      navigatorKey.currentState?.pushNamed('/student-notifications');
    } catch (e) {
      debugPrint('Error navigating on notification tap: $e');
    }
  }

  /// Check for new notices from API and trigger local notifications
  static Future<void> checkAndNotifyNewNotices() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final notices = await ApiService.getNotices();
      if (notices.isEmpty) {
        _isChecking = false;
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final List<String>? storedIds = prefs.getStringList(_notifiedIdsKey);

      // Guard: On first launch/check, store existing notice IDs without showing spam notifications
      if (storedIds == null) {
        final initialIds = notices
            .map((n) => _extractNoticeId(n))
            .where((id) => id.isNotEmpty)
            .toList();
        await prefs.setStringList(_notifiedIdsKey, initialIds);
        debugPrint('LocalNotificationService: Initialized notice list with ${initialIds.length} existing notices.');
        _isChecking = false;
        return;
      }

      final notifiedSet = Set<String>.from(storedIds);
      bool hasNewNotices = false;

      for (final notice in notices) {
        final String noticeId = _extractNoticeId(notice);
        if (noticeId.isEmpty) continue;

        if (!notifiedSet.contains(noticeId)) {
          final String title = notice['title']?.toString() ?? 'New Campus Notice';
          final String body = notice['content']?.toString() ??
              notice['description']?.toString() ??
              'A new notice has been posted on SRIMCA portal.';
          final String priority = notice['priority']?.toString().toLowerCase() ?? 'medium';

          await showNotification(
            id: noticeId.hashCode.abs(),
            title: title,
            body: body,
            payload: noticeId,
            priorityTag: priority,
          );

          notifiedSet.add(noticeId);
          hasNewNotices = true;
          debugPrint('LocalNotificationService: Notified new notice ID: $noticeId');
        }
      }

      if (hasNewNotices) {
        await prefs.setStringList(_notifiedIdsKey, notifiedSet.toList());
      }
    } catch (e) {
      debugPrint('Error during checkAndNotifyNewNotices: $e');
    } finally {
      _isChecking = false;
    }
  }

  /// Display a local notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String priorityTag = 'medium',
  }) async {
    try {
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

      await _notificationsPlugin.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error displaying local notification: $e');
    }
  }

  /// Start periodic foreground polling for new notices
  static void startPolling({Duration interval = const Duration(minutes: 3)}) {
    stopPolling();
    debugPrint('LocalNotificationService: Starting polling every ${interval.inMinutes} minutes.');
    checkAndNotifyNewNotices();
    _pollingTimer = Timer.periodic(interval, (_) {
      checkAndNotifyNewNotices();
    });
  }

  /// Stop polling timer
  static void stopPolling() {
    if (_pollingTimer != null) {
      _pollingTimer!.cancel();
      _pollingTimer = null;
      debugPrint('LocalNotificationService: Polling stopped.');
    }
  }

  /// Helper to extract notice string identifier
  static String _extractNoticeId(Map<String, dynamic> notice) {
    if (notice['id'] != null) return notice['id'].toString();
    if (notice['_id'] != null) return notice['_id'].toString();
    if (notice['title'] != null && notice['created_at'] != null) {
      return '${notice['title']}_${notice['created_at']}';
    }
    if (notice['title'] != null) return notice['title'].toString();
    return '';
  }
}
