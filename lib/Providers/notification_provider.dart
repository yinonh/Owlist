import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
// import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

import '../Widgets/notification_time.dart';

class NotificationProvider with ChangeNotifier {
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  bool _notificationsEnabled = false;
  late SharedPreferences _prefs;
  int _notificationCounter = 0;
  late NotificationTime _notificationTime;
  late bool isActive;

  FlutterLocalNotificationsPlugin get flutterLocalNotificationsPlugin =>
      _flutterLocalNotificationsPlugin;

  bool get notificationsEnabled => _notificationsEnabled;

  NotificationTime get notificationTime => _notificationTime;

  NotificationProvider() {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _initSharedPreferences();
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _notificationCounter = _prefs.getInt('notification_counter') ?? 0;
    int storedTime = _prefs.getInt('notification_time') ?? 120000;
    _notificationTime = NotificationTime.fromInt(storedTime);
    isActive = _prefs.getBool('notification_active') ?? true;
    notifyListeners();
  }

  Future<void> saveNotificationTimeToPrefs(NotificationTime time) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _notificationTime = time;
    await prefs.setInt('notification_time', time.toInt());
    notifyListeners();
  }

  Future<void> _saveCounter() async {
    await _prefs.setInt('notification_counter', _notificationCounter);
  }

  Future<void> saveActive(bool isActive) async {
    this.isActive = isActive;
    await _prefs.setBool('notification_active', isActive);
    notifyListeners();
  }

  Future<void> setUpNotifications() async {
    await _configureLocalTimeZone();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final String? timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName!));
  }

  Future<void> isAndroidPermissionGranted() async {
    final bool granted = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.areNotificationsEnabled() ??
        false;

    _notificationsEnabled = granted;
    notifyListeners();
  }

  Future<void> requestPermissions() async {
    if (isActive) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

      final bool? grantedNotificationPermission =
          await androidImplementation?.requestPermission();

      _notificationsEnabled = grantedNotificationPermission ?? false;
      notifyListeners();
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  String getRandomNotification() {
    List<String> notificationOptions = [
      "Hurry up! Tomorrow's Deadline!",
      "⏰ Reminder: Tomorrow's the Deadline!",
      "Final Call: Task Due Tomorrow!",
      "Deadline Alert: Due Tomorrow!",
      "Time's Running Out: Due Tomorrow!",
      "Don't Forget: Due Tomorrow!",
      "Last Day Reminder: Due Tomorrow!",
      "Act Now: Tomorrow's Deadline!",
      "Urgent Reminder: Due Tomorrow!",
      "Just One Day Left: Deadline Tomorrow!"
    ];
    final random = Random();
    final index = random.nextInt(notificationOptions.length);
    return notificationOptions[index];
  }

  void scheduleNotification(
      DateTime deadline, String title, BuildContext context) async {
    if (!isActive) return;
    deadline = deadline.subtract(Duration(days: 1));
    final tz.TZDateTime scheduledTime = tz.TZDateTime(
      tz.local,
      deadline.year,
      deadline.month,
      deadline.day,
      _notificationTime.hour, // Hour
      _notificationTime.minute, // Minute
      _notificationTime.second, // Second
    );
    if (scheduledTime.isBefore(DateTime.now())) return;
    _saveCounter();
    String formattedDateTime =
        DateFormat('dd/MM/yyyy HH:mm').format(scheduledTime);

    // Display Snackbar with the scheduled time
    final snackBar = SnackBar(
      content: Text(
        'Scheduled time: $formattedDateTime',
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor:
          Theme.of(context).highlightColor, // Change background color
      duration: const Duration(seconds: 3), // Set duration
      behavior: SnackBarBehavior.floating, // Change behavior to floating
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // Add border radius
      ),
      elevation: 6, // Add elevation
      margin: const EdgeInsets.all(10), // Add margin
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      _notificationCounter++,
      title,
      getRandomNotification(),
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'main_channel_id',
          'Deadline notifications',
          channelDescription:
              'Notification scheduled for one day before the deadline',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
