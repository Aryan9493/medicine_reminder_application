import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../features/medicine/data/medicine_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName.toString()));
    } catch (e) {
      print('Could not set local timezone: $e');
      // Fallback will use default (usually UTC)
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification click
      },
    );
  }

  Future<void> scheduleNotification(
    Medicine medicine, {
    bool forceNextDay = false,
  }) async {
    print('🔔 [Notification System] Scheduling Reminder:');
    print('   - Medicine: ${medicine.name}');
    print('   - Time: ${medicine.time.hour}:${medicine.time.minute}');
    print('   - ID: ${medicine.notificationId}');
    print('   - Force Next Day: $forceNextDay');

    final scheduledDate = _nextInstanceOfTime(
      medicine.time,
      forceNextDay: forceNextDay,
    );

    await _notificationsPlugin.zonedSchedule(
      medicine.notificationId,
      'Medicine Reminder',
      'Time to take ${medicine.name} (${medicine.dose})',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medicine_reminder_channel',
          'Medicine Reminders',
          channelDescription: 'Notifications for medicine reminders',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(
    DateTime time, {
    bool forceNextDay = false,
  }) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    // If we want to force next day (e.g. marked taken early) OR if the time is already passed
    if (forceNextDay || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> showInstantNotification(Medicine medicine) async {
    print('🚀 [Notification System] TEST DEMO TRIGGERED:');
    print('   - Medicine: ${medicine.name}');
    print('   - Unique ID: ${medicine.notificationId + 1000}');

    await _notificationsPlugin.show(
      medicine.notificationId + 1000,
      'Medicine Demo: ${medicine.name}',
      'This is how your reminder will look! (${medicine.dose})',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medicine_demo_channel',
          'Medicine Demos',
          channelDescription: 'Notifications for medicine demos',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> snoozeNotification(Medicine medicine, Duration duration) async {
    print(
      '💤 [Notification System] Snoozing ${medicine.name} for ${duration.inMinutes} minutes',
    );

    final snoozedTime = tz.TZDateTime.now(tz.local).add(duration);

    await _notificationsPlugin.zonedSchedule(
      medicine.notificationId +
          5000, // Different ID for snooze to avoid conflict
      'Snoozed: ${medicine.name}',
      'Reminder to take ${medicine.name} (${medicine.dose})',
      snoozedTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medicine_reminder_channel',
          'Medicine Reminders',
          channelDescription: 'Notifications for medicine reminders',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotification(int id) async {
    print('🗑️ [Notification System] Cancelling Notification ID: $id');
    await _notificationsPlugin.cancel(id);
  }
}
