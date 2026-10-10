import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
          macOS: initializationSettingsDarwin,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );
  }

  Future<bool> checkNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  Future<void> requestPermissions() async {
    // Request via permission_handler
    await Permission.notification.request();

    // Also call platform specific if needed
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
  }

  Future<void> schedulePrayerTimes(List<dynamic> monthData) async {
    // 1. Cancel all existing notifications to avoid duplicates
    await flutterLocalNotificationsPlugin.cancelAll();

    // 2. Schedule for the next 7 days (or available data)
    int scheduledCount = 0;
    final now = DateTime.now();

    // Limit to 7 days to be safe with limits (64 on iOS)
    // 5 prayers * 7 days = 35 notifications. Safe.

    for (var dayData in monthData) {
      try {
        final dateStr = dayData['date']['gregorian']['date']; // "DD-MM-YYYY"
        final dateFormat = DateFormat("dd-MM-yyyy");
        final date = dateFormat.parse(dateStr);

        // Skip past days
        // We compare YMD.
        final nowYMD = DateTime(now.year, now.month, now.day);
        if (date.isBefore(nowYMD)) continue;

        // Stop if we executed too many schedules
        if (scheduledCount >= 40) break;

        final timings = dayData['timings']; // Map of times "05:30 (EET)"

        await _schedulePrayer(date, timings['Fajr'], 'Fajr', 1);
        await _schedulePrayer(date, timings['Dhuhr'], 'Dhuhr', 2);
        await _schedulePrayer(date, timings['Asr'], 'Asr', 3);
        await _schedulePrayer(date, timings['Maghrib'], 'Maghrib', 4);
        await _schedulePrayer(date, timings['Isha'], 'Isha', 5);

        scheduledCount += 5;
      } catch (e) {
        debugPrint('Error scheduling for day: $e');
      }
    }
  }

  Future<void> _schedulePrayer(
    DateTime date,
    String timeStr,
    String prayerName,
    int prayerIdOffset,
  ) async {
    // Parse time "05:30 (EET)" -> "05:30"
    final rawTime = timeStr.split(' ')[0];
    final parts = rawTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    // Create DateTime for this prayer
    final prayerDate = DateTime(date.year, date.month, date.day, hour, minute);

    // If prayer is in the past, don't schedule
    if (prayerDate.isBefore(DateTime.now())) return;

    // Convert to TZDateTime
    final tzDate = tz.TZDateTime.from(prayerDate, tz.local);

    // Unique ID based on day and prayer
    // Hashcode of "YYYYMMDD" + prayerId
    final dateKey = int.parse(
      "${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}",
    );
    final notificationId =
        dateKey + prayerIdOffset + 100000; // Offset to avoid conflicts

    // Prayer Names Translation Map (Simple)
    final names = {
      'Fajr': 'الفجر',
      'Dhuhr': 'الظهر',
      'Asr': 'العصر',
      'Maghrib': 'المغرب',
      'Isha': 'العشاء',
    };

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      'حان الآن موعد صلاة ${names[prayerName] ?? prayerName}',
      'حي على الصلاة، حي على الفلاح',
      tzDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_channel',
          'Prayer Times',
          channelDescription: 'Notifications for prayer times',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound(
            'adhan',
          ), // Assuming we might add custom sound later, or default
        ),
        iOS: DarwinNotificationDetails(
          sound: 'adhan.aiff', // If we have one
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
