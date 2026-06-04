// lib/services/notification_service.dart
//
// Schedules four gentle daily reminders so users remember to check in
// with Milo. Uses inexact scheduling (no exact-alarm permission needed)
// and repeats daily via matchDateTimeComponents.
//
// Timezone note: Indonesia has no daylight saving, so we default to WIB
// (Asia/Jakarta). For WITA/WIT precision you can later add the
// flutter_timezone package and call tz.setLocalLocation with the
// device's real zone.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (_) {
      // Falls back to UTC if the location lookup ever fails.
    }
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    _ready = true;
  }

  /// Asks the OS for notification permission. Returns true if granted (or
  /// if no runtime prompt is required on this platform/version).
  Future<bool> requestPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final iOS = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final androidGranted = await android?.requestNotificationsPermission();
    final iosGranted = await iOS?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return androidGranted ?? iosGranted ?? true;
  }

  static const List<_Reminder> _reminders = [
    _Reminder(0, 8, 0,
        'Selamat pagi! Bagaimana perasaanmu memulai hari ini? 🌅'),
    _Reminder(1, 12, 0,
        'Jeda sejenak ya. Bagaimana siang harimu berjalan? ☀️'),
    _Reminder(2, 16, 30,
        'Sore yang tenang. Mau ceritakan perasaanmu sejauh ini? 🍵'),
    _Reminder(3, 20, 30,
        'Sebelum beristirahat, bagaimana harimu tadi? 🌙'),
  ];

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          'etmh_daily_reminders_v2',
          'Pengingat Harian',
          channelDescription:
              'Pengingat lembut untuk mencatat emosi bersama Milo.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

  /// Cancels any existing reminders and schedules a fresh daily set.
  Future<void> scheduleDailyReminders() async {
    await init();
    await cancelAll();
    for (final r in _reminders) {
      await _plugin.zonedSchedule(
        id: r.id,
        title: 'Milo menyapa 🐱',
        body: r.body,
        scheduledDate: _nextInstanceOf(r.hour, r.minute),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  /// Fires a notification immediately (no alarm scheduling) so you can
  /// verify notifications work on this device. Uses its own high-priority
  /// channel so it pops up as a heads-up notification.
  Future<void> showTestNotification() async {
    await init();
    const testDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'etmh_test',
        'Notifikasi Uji',
        channelDescription: 'Untuk menguji apakah notifikasi berfungsi.',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      id: 99,
      title: 'Halo dari Milo 🐱',
      body: 'Ini notifikasi uji. Kalau kamu melihat ini, notifikasi sudah '
          'berfungsi di HP-mu! 🌱',
      notificationDetails: testDetails,
    );
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}

class _Reminder {
  final int id;
  final int hour;
  final int minute;
  final String body;
  const _Reminder(this.id, this.hour, this.minute, this.body);
}
