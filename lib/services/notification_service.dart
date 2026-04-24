import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

/// Verse-aware, lapse-aware notification service for Rhema Study Bible.
///
/// Scheduling primitives use [zonedSchedule] with the device's local timezone
/// (via the `timezone` package). Quiet hours (10pm-7am) are enforced for all
/// schedule attempts: anything that would land inside the window is shifted
/// forward to 7:00am the next day.
///
/// Notification IDs are namespaced:
///   * 1001 - Daily Verse
///   * 2003 - Day 3 lapse re-engagement
///   * 2007 - Day 7 lapse re-engagement
///   * 3001 - Sunday weekly reflection
///   * 9001 - Internal: pause-expiry wake-up
///
/// Payload format: `verse:Book:Chapter:Verse` (deep-linked by the app shell).
class NotificationService {
  NotificationService._();

  // ── Plugin / state ───────────────────────────────────────────────────────
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // ── IDs ──────────────────────────────────────────────────────────────────
  static const int idDailyVerse = 1001;
  static const int idLapseDay3 = 2003;
  static const int idLapseDay7 = 2007;
  static const int idWeeklyReflection = 3001;
  static const int _idPauseExpiry = 9001;

  // ── Channels (Android) ───────────────────────────────────────────────────
  static const String _chDailyVerse = 'daily_verse';
  static const String _chReengagement = 'reengagement';
  static const String _chWeekly = 'weekly_reflection';

  // ── SharedPreferences keys ───────────────────────────────────────────────
  static const String _kHour = 'daily_verse_hour';
  static const String _kMinute = 'daily_verse_minute';
  static const String _kPausedUntil = 'notifications_paused_until';
  static const String _kLegacyDailyVerse = 'notif_daily_verse';
  static const String _kLegacyStudyReminder = 'notif_study_reminder';

  // ── Quiet hours (hard-coded) ─────────────────────────────────────────────
  static const int _quietStartHour = 22; // 10pm
  static const int _quietEndHour = 7;    //  7am
  static const TimeOfDay _defaultDailyVerse = TimeOfDay(hour: 8, minute: 30);
  static const TimeOfDay _quietCoercedTime = TimeOfDay(hour: 7, minute: 30);

  // ── Verse pool (rotates by day-of-year) ──────────────────────────────────
  static const List<_Verse> _dailyVersesPool = <_Verse>[
    _Verse('John', 3, 16,
        'For God so loved the world, that he gave his only begotten Son.'),
    _Verse('Psalms', 23, 1, 'The Lord is my shepherd; I shall not want.'),
    _Verse('Philippians', 4, 13,
        'I can do all things through Christ which strengtheneth me.'),
    _Verse('Jeremiah', 29, 11,
        'For I know the thoughts that I think toward you, saith the Lord.'),
    _Verse('Romans', 8, 28,
        'All things work together for good to them that love God.'),
    _Verse('Proverbs', 3, 5,
        'Trust in the Lord with all thine heart; lean not on thine own understanding.'),
    _Verse('Isaiah', 40, 31,
        'They that wait upon the Lord shall renew their strength.'),
    _Verse('Matthew', 11, 28,
        'Come unto me, all ye that labour, and I will give you rest.'),
    _Verse('Joshua', 1, 9,
        'Be strong and of a good courage; the Lord thy God is with thee.'),
    _Verse('Psalms', 46, 1,
        'God is our refuge and strength, a very present help in trouble.'),
    _Verse('2 Corinthians', 5, 17,
        'If any man be in Christ, he is a new creature.'),
    _Verse('Galatians', 5, 22,
        'The fruit of the Spirit is love, joy, peace, longsuffering.'),
    _Verse('Ephesians', 2, 8,
        'For by grace are ye saved through faith; it is the gift of God.'),
    _Verse('Hebrews', 11, 1,
        'Faith is the substance of things hoped for, the evidence of things not seen.'),
    _Verse('James', 1, 5,
        'If any of you lack wisdom, let him ask of God.'),
    _Verse('1 Peter', 5, 7, 'Casting all your care upon him; for he careth for you.'),
    _Verse('Revelation', 3, 20,
        'Behold, I stand at the door, and knock.'),
    _Verse('Psalms', 119, 105,
        'Thy word is a lamp unto my feet, and a light unto my path.'),
    _Verse('Matthew', 6, 33,
        'Seek ye first the kingdom of God, and his righteousness.'),
    _Verse('Romans', 12, 2,
        'Be not conformed to this world: but be ye transformed by the renewing of your mind.'),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // Init
  // ─────────────────────────────────────────────────────────────────────────

  /// Initializes the plugin, the timezone DB, and creates Android channels.
  /// Idempotent.
  static Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();

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

    await _createAndroidChannels();
    _initialized = true;
  }

  static Future<void> _createAndroidChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    await android.createNotificationChannel(const AndroidNotificationChannel(
      _chDailyVerse,
      'Daily Verse',
      description: 'Your verse of the day, delivered each morning.',
      importance: Importance.high,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      _chReengagement,
      'Re-engagement',
      description: 'Gentle nudges when you have not opened the app recently.',
      importance: Importance.defaultImportance,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      _chWeekly,
      'Weekly Reflection',
      description: 'Sunday evening recap of your reading.',
      importance: Importance.defaultImportance,
    ));
  }

  /// Request notification permissions (iOS + Android 13+).
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

  // ─────────────────────────────────────────────────────────────────────────
  // Daily verse
  // ─────────────────────────────────────────────────────────────────────────

  /// Schedule the daily verse notification.
  ///
  /// If [at] is provided and falls inside the quiet window, it is coerced to
  /// 7:30am. If [at] is null, the persisted user preference is used; failing
  /// that, the default of 8:30am.
  static Future<void> scheduleDailyVerse({TimeOfDay? at}) async {
    if (await isPaused()) return;

    final TimeOfDay target = at ?? await _persistedDailyTime();
    final TimeOfDay effective =
        _isInQuietHours(target.hour) ? _quietCoercedTime : target;

    await _plugin.cancel(idDailyVerse);

    final verse = _verseForToday();
    final scheduled = _nextInstanceOfTime(effective);

    await _plugin.zonedSchedule(
      idDailyVerse,
      'Verse of the Day - ${verse.reference}',
      verse.text,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _chDailyVerse,
          'Daily Verse',
          channelDescription: 'Daily verse reminder',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(verse.text),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeats daily
      payload: verse.payload,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLegacyDailyVerse, true);
  }

  /// Persist a new daily verse delivery time and reschedule.
  static Future<void> setDailyVerseTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kHour, time.hour);
    await prefs.setInt(_kMinute, time.minute);
    await scheduleDailyVerse(at: time);
  }

  static Future<TimeOfDay> _persistedDailyTime() async {
    final prefs = await SharedPreferences.getInstance();
    final h = prefs.getInt(_kHour);
    final m = prefs.getInt(_kMinute);
    if (h == null || m == null) return _defaultDailyVerse;
    return TimeOfDay(hour: h, minute: m);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Lapse re-engagement
  // ─────────────────────────────────────────────────────────────────────────

  /// Schedule day-3 and day-7 re-engagement notifications anchored to the
  /// user's last open. Both use the user's [lastBook] in the copy. Quiet-hour
  /// shifts apply per fire time.
  static Future<void> scheduleLapseReminders({
    required String lastBook,
    required DateTime lastOpenUtc,
  }) async {
    if (await isPaused()) return;

    await cancelLapseReminders();

    final last = tz.TZDateTime.from(lastOpenUtc, tz.local);
    final day3 = _shiftIfQuiet(last.add(const Duration(days: 3)));
    final day7 = _shiftIfQuiet(last.add(const Duration(days: 7)));

    final book = lastBook.trim().isEmpty ? 'Scripture' : lastBook.trim();

    await _plugin.zonedSchedule(
      idLapseDay3,
      'Continue your journey in $book',
      'Pick up where you left off - your bookmark is waiting.',
      day3,
      _reengagementDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'reengagement:day3:$book',
    );

    await _plugin.zonedSchedule(
      idLapseDay7,
      'A week away from $book',
      'Your reading plan is paused - tap to resume.',
      day7,
      _reengagementDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'reengagement:day7:$book',
    );
  }

  /// Cancel both re-engagement notifications. Call this on every app open.
  static Future<void> cancelLapseReminders() async {
    await _plugin.cancel(idLapseDay3);
    await _plugin.cancel(idLapseDay7);
  }

  static NotificationDetails _reengagementDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _chReengagement,
        'Re-engagement',
        channelDescription: 'Gentle nudges when you have not opened the app.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Weekly reflection (Sunday 6pm)
  // ─────────────────────────────────────────────────────────────────────────

  /// Every Sunday at 6:00pm local time.
  static Future<void> scheduleWeeklyReflection() async {
    if (await isPaused()) return;

    await _plugin.cancel(idWeeklyReflection);

    final scheduled = _nextSundayAt(hour: 18, minute: 0);

    await _plugin.zonedSchedule(
      idWeeklyReflection,
      'Your week in Scripture',
      'Tap to see your reading recap.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _chWeekly,
          'Weekly Reflection',
          channelDescription: 'Sunday evening recap of your reading.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'reflection:weekly',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Pause
  // ─────────────────────────────────────────────────────────────────────────

  /// Cancels all scheduled notifications and disables scheduling for 7 days.
  /// Schedules a single internal wake-up that re-enables on expiry.
  static Future<void> pauseFor7Days() async {
    final prefs = await SharedPreferences.getInstance();
    final until = DateTime.now().add(const Duration(days: 7));
    await prefs.setInt(_kPausedUntil, until.millisecondsSinceEpoch);

    await _plugin.cancelAll();

    // Schedule wake-up (slightly past quiet window if needed).
    final wake = _shiftIfQuiet(tz.TZDateTime.from(until, tz.local));
    await _plugin.zonedSchedule(
      _idPauseExpiry,
      'Notifications resumed',
      'Welcome back - your daily verse will arrive tomorrow.',
      wake,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _chDailyVerse,
          'Daily Verse',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'pause:expired',
    );
  }

  /// True iff the user is currently within a 7-day pause window.
  /// Auto-clears the pref once the window passes.
  static bool isPausedSync(SharedPreferences prefs) {
    final until = prefs.getInt(_kPausedUntil);
    if (until == null) return false;
    if (DateTime.now().millisecondsSinceEpoch >= until) {
      prefs.remove(_kPausedUntil);
      return false;
    }
    return true;
  }

  /// Async version - fetches prefs internally.
  static Future<bool> isPaused() async {
    final prefs = await SharedPreferences.getInstance();
    return isPausedSync(prefs);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Cancellation
  // ─────────────────────────────────────────────────────────────────────────

  /// Cancel all scheduled notifications.
  static Future<void> cancelAll() => _plugin.cancelAll();

  /// Cancel a specific notification by ID.
  static Future<void> cancel(int id) => _plugin.cancel(id);

  // ─────────────────────────────────────────────────────────────────────────
  // Backward compatibility shims
  // ─────────────────────────────────────────────────────────────────────────

  /// Legacy alias for the old "study reminder" toggle. Now a no-op stand-in
  /// that schedules the daily verse if not already scheduled. Existing
  /// callers in `settings_screen.dart` continue to work.
  @Deprecated('Use scheduleDailyVerse() or scheduleLapseReminders() instead.')
  static Future<void> scheduleStudyReminder() async {
    // Map legacy "study reminder" intent onto the daily verse.
    await scheduleDailyVerse();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLegacyStudyReminder, true);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Internal helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// 10pm-7am inclusive on the start, exclusive on the end. Hours 22, 23, 0,
  /// 1, 2, 3, 4, 5, 6 are quiet; hour 7 is allowed.
  static bool _isInQuietHours(int hour) {
    return hour >= _quietStartHour || hour < _quietEndHour;
  }

  /// If the given instant lands inside quiet hours, shift it to 7:00am the
  /// next day in local tz. Otherwise return unchanged.
  static tz.TZDateTime _shiftIfQuiet(tz.TZDateTime when) {
    if (!_isInQuietHours(when.hour)) return when;
    final base = when.hour >= _quietStartHour
        ? when.add(const Duration(days: 1))
        : when;
    return tz.TZDateTime(
      tz.local,
      base.year,
      base.month,
      base.day,
      _quietEndHour,
      0,
    );
  }

  /// Next instance of [t] in the local timezone, in the future.
  static tz.TZDateTime _nextInstanceOfTime(TimeOfDay t) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, t.hour, t.minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Next Sunday at the given hour:minute, local timezone.
  /// `DateTime.weekday`: Mon=1 ... Sun=7.
  static tz.TZDateTime _nextSundayAt({required int hour, required int minute}) {
    final now = tz.TZDateTime.now(tz.local);
    final daysUntilSunday = (DateTime.sunday - now.weekday + 7) % 7;
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    scheduled = scheduled.add(Duration(days: daysUntilSunday));
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }
    return scheduled;
  }

  /// Pick today's verse deterministically by day-of-year.
  static _Verse _verseForToday() {
    final now = DateTime.now();
    final dayOfYear = int.parse(
        '${now.difference(DateTime(now.year, 1, 1)).inDays + 1}');
    return _dailyVersesPool[dayOfYear % _dailyVersesPool.length];
  }
}

/// Internal verse value object.
class _Verse {
  final String book;
  final int chapter;
  final int verse;
  final String text;

  const _Verse(this.book, this.chapter, this.verse, this.text);

  String get reference => '$book $chapter:$verse';

  /// Payload format: `verse:Book:Chapter:Verse` (e.g. `verse:John:3:16`).
  String get payload => 'verse:$book:$chapter:$verse';
}
