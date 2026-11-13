
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/schedule_model.dart';

class NotificationServices {
  NotificationServices._();

  static final NotificationServices instance = NotificationServices._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _settingsKey = 'notification_schedule_settings';

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    final String timeZoneName =
        await FlutterTimezone.getLocalTimezone();

    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings: initializationSettings,
    );

    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();

    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final granted =
          await android.requestNotificationsPermission();
      return granted ?? false;
    }

    final ios = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      return granted ?? false;
    }

    return false;
  }

  Future<ScheduleModel> loadSettings() async {
    final preferences = await SharedPreferences.getInstance();

    final savedData = preferences.getString(_settingsKey);

    if (savedData == null) {
      return const ScheduleModel();
    }

    try {
      final Map<String, dynamic> decoded =
          jsonDecode(savedData) as Map<String, dynamic>;

      return ScheduleModel.fromMap(decoded);
    } catch (_) {
      return const ScheduleModel();
    }
  }

  Future<bool> saveSettings(ScheduleModel settings) async {
    await initialize();

    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      _settingsKey,
      jsonEncode(settings.toMap()),
    );

    final hasEnabledReminder = settings.waterEnabled ||
        settings.breakfastEnabled ||
        settings.lunchEnabled ||
        settings.dinnerEnabled;

    await _notifications.cancelAll();

    if (!hasEnabledReminder) {
      return true;
    }

    final permissionGranted = await requestPermission();

    if (!permissionGranted) {
      return false;
    }

    await _scheduleAll(settings);

    return true;
  }

  Future<void> _scheduleAll(ScheduleModel settings) async {
    if (settings.waterEnabled) {
      await _scheduleWaterReminders(settings);
    }

    if (settings.breakfastEnabled) {
      await _scheduleDailyReminder(
        id: 2001,
        title: 'Waktunya Sarapan',
        body: 'Jangan lupa sarapan untuk memulai aktivitasmu.',
        minutes: settings.breakfastMinutes,
      );
    }

    if (settings.lunchEnabled) {
      await _scheduleDailyReminder(
        id: 2002,
        title: 'Waktunya Makan Siang',
        body: 'Jangan lupa makan siang agar energi tetap terjaga.',
        minutes: settings.lunchMinutes,
      );
    }

    if (settings.dinnerEnabled) {
      await _scheduleDailyReminder(
        id: 2003,
        title: 'Waktunya Makan Malam',
        body: 'Saatnya makan malam. Tetap jaga pola makan sehat.',
        minutes: settings.dinnerMinutes,
      );
    }
  }

  Future<void> _scheduleWaterReminders(
    ScheduleModel settings,
  ) async {
    final start = settings.waterStartMinutes;
    final end = settings.waterEndMinutes;
    final interval = settings.waterIntervalMinutes;

    if (interval <= 0 || start >= end) return;

    int notificationId = 1000;

    for (int minutes = start + interval;
        minutes <= end;
        minutes += interval) {
      final hour = minutes ~/ 60;
      final minute = minutes % 60;

      await _scheduleNotification(
        id: notificationId++,
        title: 'Waktunya Minum Air',
        body: 'Jangan lupa minum air putih agar tubuh tetap terhidrasi.',
        hour: hour,
        minute: minute,
      );
    }
  }

  Future<void> _scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int minutes,
  }) async {
    await _scheduleNotification(
      id: id,
      title: title,
      body: body,
      hour: minutes ~/ 60,
      minute: minutes % 60,
    );
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Jika waktunya sudah lewat, jadwalkan pada hari berikutnya.
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'health_reminder_channel',
        'Pengingat Kesehatan',
        channelDescription: 'Pengingat minum air dan jadwal makan',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelAllNotifications() async {
    await initialize();
    await _notifications.cancelAll();
  }
}

