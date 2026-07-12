import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(settings: initSettings);
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    _isInitialized = true;
  }

  Future<bool> _areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications') ?? true;
  }



  Future<void> scheduleDueReminder(double balance, String cashbookName) async {
    // Only schedule if there is a significant due amount (e.g. > 100)
    if (balance.abs() < 100) return;
    if (!await _areNotificationsEnabled()) return;

    // Cancel existing due reminder to avoid spam
    await _notificationsPlugin.cancel(666);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'due_channel',
          'Due Reminders',
          channelDescription: 'Reminders for outstanding balances',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFF4143D5),
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    // Schedule for 3 days from now
    final scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(days: 3));

    final isYouOwe = balance < 0; // Assuming negative balance means you owe money
    final title = isYouOwe ? 'Payment Due Reminder' : 'Collection Due Reminder';
    final body = isYouOwe 
        ? 'You have an outstanding balance of ₹${balance.abs().toStringAsFixed(0)} in $cashbookName. Don\'t forget to pay!'
        : 'You need to collect ₹${balance.abs().toStringAsFixed(0)} in $cashbookName. Send a reminder!';

    await _notificationsPlugin.zonedSchedule(
      id: 666,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> showUpdateNotification({String version = '1.1.0'}) async {
    if (!await _areNotificationsEnabled()) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'updates_channel',
          'App Updates',
          channelDescription: 'Notifications for app updates',
          importance: Importance.max,
          priority: Priority.max,
          color: Color(0xFF4143D5),
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id: 999, // Static ID so it overwrites previous update notifications
      title: 'SmartKhata Update Available',
      body: 'Version $version is out! Tap to install new features.',
      notificationDetails: details,
    );
  }

  Future<void> scheduleInactivityReminder() async {
    // Cancel any existing inactivity reminder first
    await _notificationsPlugin.cancel(id: 888);

    if (!await _areNotificationsEnabled()) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'reminder_channel',
          'Reminders',
          channelDescription: 'Reminders to log transactions',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: Color(0xFF4143D5),
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    // Schedule for 2 days from now
    final scheduledDate = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(days: 2));

    await _notificationsPlugin.zonedSchedule(
      id: 888,
      title: 'We miss you!',
      body:
          'You haven\'t logged any transactions recently. Keep your SmartKhata up to date!',
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> scheduleDailyReminder() async {
    await _notificationsPlugin.cancel(id: 777); // Cancel existing if any
    if (!await _areNotificationsEnabled()) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'daily_reminder_channel',
          'Daily Reminders',
          channelDescription: 'Daily reminder to log expenses',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: Color(0xFF4143D5),
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    // Schedule for 8:00 PM today, or tomorrow if it's already past 8:00 PM
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      20,
      0,
    ); // 8:00 PM
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      id: 777,
      title: 'Daily Check-in',
      body: 'Did you spend any money today? Don\'t forget to log it!',
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> showMilestoneNotification(int totalRecords) async {
    if (!await _areNotificationsEnabled()) return;

    // Only trigger on exact milestones
    if (![10, 50, 100, 500].contains(totalRecords)) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'milestone_channel',
          'Milestones',
          channelDescription: 'Notifications for app milestones',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFF4143D5),
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id: 666 + totalRecords, // Unique ID for each milestone
      title: 'Congratulations! 🎉',
      body:
          'You have logged $totalRecords transactions! Great job managing your finances!',
      notificationDetails: details,
    );
  }
}
