import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _dailyVerseChannelId = 'daily_verse';
  static const _studyReminderChannelId = 'study_reminder';

  /// Initialize the notification plugin
  static Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    _initialized = true;
  }

  /// Request notification permissions (iOS + Android 13+)
  static Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (android != null) {
      await android.requestNotificationsPermission();
    }
    if (ios != null) {
      await ios.requestPermissions(alert: true, badge: true, sound: true);
    }
    return true;
  }

  /// Schedule a daily repeating notification for verse of the day
  static Future<void> scheduleDailyVerse() async {
    await _plugin.periodicallyShow(
      0,
      'Verse of the Day',
      'Your daily verse is waiting. Start your day with God\'s Word.',
      RepeatInterval.daily,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _dailyVerseChannelId,
          'Daily Verse',
          channelDescription: 'Daily verse reminder',
          importance: Importance.high,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'daily_verse',
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_daily_verse', true);
  }

  /// Schedule a daily repeating notification for study plan reminder
  static Future<void> scheduleStudyReminder() async {
    await _plugin.periodicallyShow(
      1,
      'Time to Study',
      'Don\'t break your streak! Your reading plan is waiting.',
      RepeatInterval.daily,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _studyReminderChannelId,
          'Study Reminder',
          channelDescription: 'Daily study plan reminder',
          importance: Importance.high,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'study_reminder',
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_study_reminder', true);
  }

  /// Cancel all notifications
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Cancel a specific notification by ID
  static Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }
}
